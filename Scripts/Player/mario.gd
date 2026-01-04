extends CharacterBody2D

# ========================================
# CONSTANTS
# ========================================
const SPEEDS = {"walk": 80.0, "run": 150.0}
const PHYSICS = {"acceleration": 100.0, "friction": 600.0, "jump": -380.0}

# ========================================
# STATE & VARIABLES
# ========================================
enum VisualState { IDLE, WALK, RUNNING, JUMPING, CROUCHING, TURNING  }
var current_visual_state: VisualState = VisualState.IDLE
var entering_pipe := false
var current_pipe: Area2D
var turning_timer := 0.0
var turning_duration := 0.2

var last_direction := 1
var was_running_when_jumped := false
var jump_was_cut := false
var was_in_air := false

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
	"turn": $Mario_Turn,
	"jump_run": $Mario_Jump_Run,
	"jump": $Mario_Jump,
	"crouch": $Mario_Crouched
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
	if entering_pipe or game_manager.mario_is_respawning or game_manager.mario_is_dead:
		return
	
	handle_gravity(delta)
	handle_jump()
	handle_movement(delta)
	handle_interactions()
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
		was_running_when_jumped = Input.is_action_pressed("ui_run")
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
	var is_running = Input.is_action_pressed("ui_run")
	var max_speed = SPEEDS.run if is_running else SPEEDS.walk
	
	if turning_timer > 0:
		turning_timer -= delta
	
	if direction != 0:
		if is_changing_direction(direction):
			apply_friction(delta)
			if is_running:
				turning_timer = turning_duration
				set_visual_state(VisualState.TURNING)
		elif turning_timer <= 0:
			apply_movement(direction, max_speed, is_running, delta)
			if is_running:
				set_visual_state(VisualState.RUNNING)
			else:
				set_visual_state(VisualState.WALK)

		update_movement_visuals(direction, max_speed)
	else:
		apply_friction(delta)
		turning_timer = 0

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
	sprites.idle.flip_h = flip

	last_direction = 1 if direction > 0 else -1

# ========================================
# VISUAL STATE SYSTEM
# ========================================
func update_visuals():
	var direction = Input.get_axis("ui_left", "ui_right")
	var is_crouching = is_on_floor() and direction == 0 and Input.is_action_pressed("ui_down")
	var is_jumping = not is_on_floor()
	
	if is_crouching:
		set_visual_state(VisualState.CROUCHING)
	elif is_jumping:
		set_visual_state(VisualState.JUMPING)
	elif direction == 0:
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
		VisualState.JUMPING:
			if was_running_when_jumped:
				sprites.jump_run.visible = true
				sprites.jump_run.flip_h = last_direction < 0
			else:
				sprites.jump.visible = true
				sprites.jump.flip_h = last_direction < 0 
			anim_mario.stop()
		VisualState.CROUCHING:
			sprites.crouch.visible = true
		VisualState.TURNING:
			sprites.turn.visible = true
			sprites.turn.flip_h = last_direction < 0
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
	if global_position.y > 230:
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
		global_position = to_pipe.center.global_position + to_pipe.enter_direction * 32

		var exit_tween = create_tween()
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
