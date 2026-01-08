extends CharacterBody2D

# ========================================
# CONSTANTS
# ========================================
const SPEEDS = {"walk": 80.0, "run": 150.0}
const PHYSICS = {"acceleration": 100.0, "friction": 300.0, "jump": -380.0}
const WALL_JUMP = {"force": Vector2(200, -300), "slide_gravity": 0.3}

# ========================================
# STATE & VARIABLES
# ========================================
enum VisualState { IDLE, WALK, RUNNING, DIE, JUMPING, CROUCHING, TURNING, DAMAGE, WALL_SLIDING, FLAG_SLIDING  }
var current_visual_state: VisualState = VisualState.IDLE
var entering_pipe := false
var current_pipe: Area2D
var turning_timer := 0.0
var turning_duration := 0.2
var ignore_input_timer := 0.0
var ignore_input_duration := 0.1
var is_wall_sliding := false
var wall_jump_cooldown := 0.0
var wall_jump_cooldown_time := 0.2

var last_direction := 1
var velocity_when_jumped := 0.0
var jump_was_cut := false
var was_in_air := false
var is_flag_sliding := false
var is_walk_to_castle := false

# ========================================
# SIGNAIS
# ========================================
signal mario_died
signal fell_off_world()
signal damage_received(from_enemy: Node2D)
signal enemy_stomped(enemy: Node2D)
signal block_hit(block: Node2D)

# ========================================
# NODE REFERENCES
# ========================================
@onready var sprites = {
	"idle": $Mario,
	"walk": $Mario_Walk,
	"run":  $Mario_Run,
	"die": $Mario_death,
	"turn": $Mario_Turn,
	"jump_run": $Mario_Jump_Run,
	"jump": $Mario_Jump,
	"crouch": $Mario_Crouched,
	"damage": $Mario_Damage,
	"wall_jump" : $WALL_SLIDING,
	"flag_slide" : $Mario_Flag_Slide,
	"victory" : $Mario_Win
}
@onready var collisions = {
	"normal": $CollisionNormal,
	"crouched": $CollisionCrouched
}
@onready var HurtBox = $HurtBox
@onready var anim_mario = $AnimationPlayer

# ========================================
# FUNCTION READY
# ========================================
func _ready():
	HurtBox.body_entered.connect(_on_hurt_box_body_entered)
	Game.register_mario(self)  # Mario se registra no Game

# ========================================
# MAIN PHYSICS LOOP
# ========================================
func _physics_process(delta: float) -> void:
	var game_manager = Game
	if entering_pipe or game_manager.mario_is_respawning or is_flag_sliding or is_walk_to_castle: 
		if not is_walk_to_castle:
			return
		handle_gravity(delta)
		move_and_slide()
		return
	
	if game_manager.mario_is_dead:
		# Durante morte, só processa gravidade e movimento
		handle_gravity(delta)
		move_and_slide()
		return
	
	handle_gravity(delta)
	handle_jump()
	handle_movement(delta)
	handle_interactions()
	handle_wall_mechanics(delta)
	update_visuals()
	
	handle_landing()
	move_and_slide()

# ========================================
# PHYSICS HANDLERS
# ========================================
func handle_gravity(delta: float):
	if not is_on_floor():
		velocity += get_gravity() * delta

func handle_jump():
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity_when_jumped = abs(velocity.x)  # Captura velocidade antes do pulo
		velocity.y = PHYSICS.jump
		jump_was_cut = false  # Reset da flag
		was_in_air = true  # Marca que saiu do chão
		# Não toca som aqui ainda
		
	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= 0.5
		jump_was_cut = true  # Marca que foi cortado
		AudioManager.play_sfx("jump_small")  # Som de pulo curto

# Adicione esta função para detectar quando Mario pousa
func handle_landing():
	if is_on_floor() and was_in_air and not jump_was_cut:
		AudioManager.play_sfx("jump_super")
	
	if is_on_floor():
		was_in_air = false  # Reset - não está mais no ar
		jump_was_cut = false

func handle_movement(delta: float):
	var direction = Input.get_axis("ui_left", "ui_right")
	if ignore_input_timer > 0:
		direction = 0
	var is_running = Input.is_action_pressed("ui_run")
	var max_speed = SPEEDS.run if is_running else SPEEDS.walk
	
	if turning_timer > 0:
		turning_timer -= delta
	
	if direction != 0:
		if is_changing_direction(direction):
			apply_friction(delta)
			if is_running and abs(velocity.x) > SPEEDS.walk:
				turning_timer = turning_duration
				set_visual_state(VisualState.TURNING)
		elif turning_timer <= 0:
			apply_movement(direction, max_speed, is_running, delta)
			if abs(velocity.x) > 130:
				set_visual_state(VisualState.RUNNING)
			else:
				set_visual_state(VisualState.WALK)

		update_movement_visuals(direction, max_speed)
	else:
		apply_friction(delta)
		turning_timer = 0
		
		# NOVA LÓGICA: Se ainda tem velocidade, usa TURNING
		if abs(velocity.x) > 5.0:  # Threshold pequeno para evitar tremulação
			set_visual_state(VisualState.TURNING)

# ========================================
# MOVEMENT HELPERS
# ========================================
func apply_movement(direction: float, max_speed: float, is_running: bool, delta: float):
	if is_running:
		velocity.x = move_toward(velocity.x, direction * max_speed, PHYSICS.acceleration * delta)
	else:
		velocity.x = direction * SPEEDS.walk

func apply_friction(delta: float):
	velocity.x = move_toward(velocity.x, 0, PHYSICS.friction * delta)

func is_changing_direction(direction: float) -> bool:
	return sign(velocity.x) != sign(direction) and velocity.x != 0

func update_movement_visuals(direction: float, max_speed: float):
	var speed_ratio = clamp(abs(velocity.x) / max_speed, 0.2, 1.0)
	anim_mario.speed_scale = speed_ratio
	
	var flip = direction < 0
	sprites.walk.flip_h = flip
	sprites.run.flip_h = flip
	sprites.jump_run.flip_h = flip
	sprites.crouch.flip_h = flip
	sprites.idle.flip_h = flip

	last_direction = 1 if direction > 0 else -1

# ========================================
# VISUAL STATE SYSTEM
# ========================================
func update_visuals():
	if Game.mario_is_invincible:
		set_visual_state(VisualState.DAMAGE)
		return
	if is_flag_sliding:
		set_visual_state(VisualState.FLAG_SLIDING)
		return
	if is_walk_to_castle:
		return
	
	var direction = Input.get_axis("ui_left", "ui_right")
	var is_crouching = is_on_floor() and direction == 0 and Input.is_action_pressed("ui_down")
	var is_jumping = not is_on_floor()
	
	if is_crouching:
		set_visual_state(VisualState.CROUCHING)
	elif is_wall_sliding:  # ADICIONE ESTA LINHA ANTES DE is_jumping
		set_visual_state(VisualState.WALL_SLIDING)
	elif is_jumping:
		set_visual_state(VisualState.JUMPING)
		if velocity_when_jumped > 130:
			sprites.jump_run.visible = true
			sprites.jump.visible = false
			sprites.jump_run.flip_h = last_direction < 0
		else:
			sprites.jump.visible = true
			sprites.jump_run.visible = false
			sprites.jump.flip_h = last_direction < 0
	elif direction == 0 and abs(velocity.x) <= 5.0:
		set_visual_state(VisualState.IDLE)

func set_visual_state(state: VisualState):
	if current_visual_state == state:
		return
	
	current_visual_state = state
	
	for sprite in sprites.values():
		sprite.visible = false
	
	match state:
		VisualState.IDLE:
			sprites.idle.visible = true
			anim_mario.speed_scale = 1.0
		VisualState.WALK:
			sprites.walk.visible = true
			if anim_mario.current_animation != "walk":
				anim_mario.play("walk")
		VisualState.RUNNING:
			sprites.run.visible = true
			if anim_mario.current_animation != "run":
				anim_mario.play("run")
		VisualState.DIE:
			sprites.die.visible = true
			if anim_mario.current_animation != "die":
				await get_tree().create_timer(0.5).timeout
				anim_mario.play("die")
		VisualState.JUMPING:
			anim_mario.stop()
		VisualState.CROUCHING:
			sprites.crouch.visible = true
		VisualState.DAMAGE:
			sprites.damage.visible = true
		VisualState.TURNING:
			sprites.turn.visible = true
			sprites.turn.flip_h = last_direction < 0
			anim_mario.stop()
		VisualState.WALL_SLIDING:
			sprites.wall_jump.visible = true
			sprites.wall_jump.flip_h = get_wall_normal().x < 0
			anim_mario.stop()
		VisualState.FLAG_SLIDING:
			sprites.flag_slide.visible = true
			anim_mario.stop()
	
	var is_crouching = state == VisualState.CROUCHING
	collisions.normal.disabled = is_crouching
	collisions.crouched.disabled = not is_crouching

# ========================================
# INTERACTION HANDLERS
# ========================================
func handle_interactions():
	handle_ceiling_collision()
	handle_floor_collision()
	handle_pipe_interaction()
	check_fall_death()

func check_fall_death():
	if entering_pipe:
		return
	if global_position.y > Game.get_death_y_limit():
		fell_off_world.emit()

func handle_ceiling_collision():
	if is_on_ceiling():
		var collision = get_last_slide_collision()
		if collision:
			var collider = collision.get_collider()
			if collider.is_in_group("question_block") or collider.is_in_group("blocks"):
				block_hit.emit(collider)
				collider.hit()

func handle_floor_collision():
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision == null:
			continue

		var collider = collision.get_collider()
		if collider == null:
			continue

		if collision.get_normal().y < -0.7:
			if collider.is_in_group("enemies"):
				# VERIFICAR SE O INIMIGO JÁ FOI PISADO
				if collider.has_method("is_stomped") and collider.is_stomped():
					continue
					
				if collider.is_in_group("piranha_plant"):
					damage_received.emit(collider)
				else:
					enemy_stomped.emit(collider)
					collider.stomped()
					velocity.y = -200

func _on_hurt_box_body_entered(body):
	if body.is_in_group("enemies"):
		damage_received.emit(body)
		

func handle_pipe_interaction():
	if current_pipe and is_on_floor() and not entering_pipe:
		if Input.is_action_pressed("ui_down"):
			enter_pipe()
			
# ========================================
# Wall jump
# ========================================
func handle_wall_mechanics(delta: float):
	if ignore_input_timer > 0:
		ignore_input_timer -= delta
	
	# 1. Reduzir cooldown
	if wall_jump_cooldown > 0:
		wall_jump_cooldown -= delta
	
	# 2. Detectar se está em wall slide
	var direction = Input.get_axis("ui_left", "ui_right")
	var touching_wall = is_on_wall()
	var moving_into_wall = direction != 0 and touching_wall
	var in_air = not is_on_floor()
	
	is_wall_sliding = touching_wall and in_air and moving_into_wall and wall_jump_cooldown <= 0
	
	# 3. Aplicar wall slide gravity
	if is_wall_sliding:
		velocity.y = min(velocity.y, 50)  # Limita velocidade de queda
	
	# 4. Wall jump
	if is_wall_sliding and Input.is_action_just_pressed("ui_accept"):
		perform_wall_jump()

func perform_wall_jump():
	var wall_normal = get_wall_normal()
	
	velocity.x = wall_normal.x * WALL_JUMP.force.x
	velocity.y = WALL_JUMP.force.y
	
	wall_jump_cooldown = wall_jump_cooldown_time
	is_wall_sliding = false
	ignore_input_timer = ignore_input_duration  # ADICIONE ESTA LINHA
	
	AudioManager.play_sfx("jump_small")
	
# ========================================
# FLAG SLIDING SYSTEM
# ========================================
func start_flag_sliding():
	is_flag_sliding = true
	velocity = Vector2.ZERO  # Para o Mario
	set_visual_state(VisualState.FLAG_SLIDING)  # ADICIONE ESTA LINHA

func stop_flag_sliding():
	is_flag_sliding = false

# ========================================
# PIPE SYSTEM
# ========================================
func enter_pipe():
	if not is_instance_valid(current_pipe) or not is_instance_valid(current_pipe.linked_pipe):
		return

	entering_pipe = true
	velocity = Vector2.ZERO

	var from_pipe = current_pipe
	var to_pipe = current_pipe.linked_pipe

	global_position = from_pipe.center.global_position

	AudioManager.play_sfx("pipe")
	var enter_tween = create_tween()
	enter_tween.tween_property(
		self,
		"global_position",
		from_pipe.center.global_position + from_pipe.enter_direction * 32,
		0.4
	)

	enter_tween.finished.connect(func():
		if to_pipe.exit_direction.y > 0: # Sai para baixo
			global_position = to_pipe.center.global_position
		else: # Sai para cima
			global_position = to_pipe.center.global_position + Vector2(0, 32)
		
		if is_instance_valid(to_pipe) and to_pipe.has_method("get") and "pipe_zone" in to_pipe:
			print("ENTRANDO NO CANO! Zona do destino: ", to_pipe.pipe_zone)
			Game.change_zone(to_pipe.pipe_zone)
		else:
			print("ERRO: to_pipe é inválido ou não tem pipe_zone")
			print("to_pipe: ", to_pipe)
			
		var exit_tween = create_tween()
		
		if to_pipe.exit_direction.y > 0:
			exit_tween.tween_property(
				self,
				"global_position",
				to_pipe.center.global_position + to_pipe.enter_direction * 32,
				0.35
			)
		else:
			exit_tween.tween_property(
				self,
				"global_position",
				to_pipe.center.global_position,
				0.35
			)
		
		set_visual_state(VisualState.IDLE)

		exit_tween.finished.connect(func():
			entering_pipe = false
			current_pipe = to_pipe
		)
	)
