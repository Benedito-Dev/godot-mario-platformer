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
var spawn_position: Vector2 = Vector2.ZERO
var is_respawning := false
var is_dead := false
var lives := 3
var is_invincible := false
var invincible_time := 1.0
var turning_timer := 0.0
var turning_duration := 0.2  # Tempo em segundos para mostrar a sprite de virada

var last_direction := 1  # 1 = direita, -1 = esquerda
var was_running_when_jumped := false # Estava correndo na hora que pulei

# ========================================
# SIGNAIS
# ========================================
signal mario_died
signal mario_entered_pipe

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
@onready var death_sound = $DeathSound
@onready var pipe_sound = $PipeSound

# ========================================
# FUNCTION READY ( SPAWN INITIAL )
# ========================================
func _ready():
	spawn_position = global_position # Spawn inicial na posição atual
	HurtBox.body_entered.connect(_on_hurt_box_body_entered)

# ========================================
# MAIN PHYSICS LOOP
# ========================================
func _physics_process(delta: float) -> void:
	if entering_pipe or is_respawning or is_dead:
		return
	
	handle_gravity(delta)
	handle_jump()
	handle_movement(delta)
	handle_interactions()
	update_visuals()
	
	move_and_slide()


# ========================================
# PHYSICS HANDLERS
# ========================================
func handle_gravity(delta: float):
	"""Apply gravity when not on floor"""
	if not is_on_floor():
		velocity += get_gravity() * delta


func handle_jump():
	"""Handle jump input"""
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		was_running_when_jumped = Input.is_action_pressed("ui_run")
		velocity.y = PHYSICS.jump


func handle_movement(delta: float):
	"""Handle horizontal movement with acceleration/friction"""
	var direction = Input.get_axis("ui_left", "ui_right")
	var is_running = Input.is_action_pressed("ui_run")
	var max_speed = SPEEDS.run if is_running else SPEEDS.walk
	
	if turning_timer > 0:
		turning_timer -= delta
	
	if direction != 0:
		# Moving - apply movement or braking
		if is_changing_direction(direction):
			apply_friction(delta)  # Brake when changing direction
			if is_running: # virada somentte quando esta correndo
				turning_timer = turning_duration
				set_visual_state(VisualState.TURNING)
		elif turning_timer <= 0:  # Só muda sprite se não estiver virando :
			apply_movement(direction, max_speed, is_running, delta)
			if is_running:
				set_visual_state(VisualState.RUNNING)
			else:
				set_visual_state(VisualState.WALK)

		# Visual updates (independent of braking)
		update_movement_visuals(direction, max_speed)
	else:
		# Stopped - apply friction
		apply_friction(delta)
		turning_timer = 0


# ========================================
# MOVEMENT HELPERS
# ========================================
func apply_movement(direction: float, max_speed: float, is_running: bool, delta: float):
	"""Apply acceleration or instant movement"""
	if is_running:
		velocity.x = move_toward(velocity.x, direction * max_speed, PHYSICS.acceleration * delta)
	else:
		velocity.x = direction * SPEEDS.walk


func apply_friction(delta: float):
	"""Apply friction to slow down"""
	velocity.x = move_toward(velocity.x, 0, PHYSICS.friction * delta)


func is_changing_direction(direction: float) -> bool:
	"""Check if player is changing direction while moving"""
	return sign(velocity.x) != sign(direction) and velocity.x != 0


func update_movement_visuals(direction: float, max_speed: float):
	"""Update sprite direction and animation speed"""
	# Animation speed based on current velocity
	var speed_ratio = clamp(abs(velocity.x) / max_speed, 0.2, 1.0)
	anim_mario.speed_scale = speed_ratio
	
	# Sprite direction
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
	"""Determine and set visual state based on current conditions"""
	var direction = Input.get_axis("ui_left", "ui_right")
	var is_crouching = is_on_floor() and direction == 0 and Input.is_action_pressed("ui_down")
	var is_jumping = not is_on_floor()
	
	if is_crouching:
		set_visual_state(VisualState.CROUCHING)
	elif is_jumping:
		set_visual_state(VisualState.JUMPING)
	elif direction == 0:
		set_visual_state(VisualState.IDLE)
	# RUNNING state is set in handle_movement()


func set_visual_state(state: VisualState):
	"""Change visual state and update sprites/collisions"""
	if current_visual_state == state:
		return
	
	current_visual_state = state
	
	# Hide all sprites
	for sprite in sprites.values():
		sprite.visible = false
	
	# Show active sprite and configure
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
	
	# Update collision shape
	var is_crouching = state == VisualState.CROUCHING
	collisions.normal.disabled = is_crouching
	collisions.crouched.disabled = not is_crouching


# ========================================
# INTERACTION HANDLERS
# ========================================
func handle_interactions():
	"""Handle all player interactions"""
	handle_ceiling_collision()
	handle_floor_collision()
	handle_pipe_interaction()
	check_fall_death()
	# Adicionar em handle_interactions()
	if Input.is_action_just_pressed("ui_text_backspace"):
		respawn()
		
func check_fall_death():
	"""Check if Mario fell off the world"""
	if global_position.y > 230:
		die()

func handle_ceiling_collision():
	"""Handle hitting blocks above"""
	if is_on_ceiling():
		var collision = get_last_slide_collision()
		if collision:
			var collider = collision.get_collider()
			if collider.is_in_group("question_block") or collider.is_in_group("blocks"):
				collider.hit()

func handle_floor_collision():
	# Percorre todas as colisões do frame
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision == null:
			continue

		var collider = collision.get_collider()
		if collider == null:
			continue

		# Normal apontando para cima = Mario caiu em cima
		if collision.get_normal().y < -0.7:
			if collider.is_in_group("enemies"):
				collider.stomped()
				velocity.y = -200 # quicada estilo Mario
				
func _on_hurt_box_body_entered(body):
	if body.is_in_group("enemies"):
		take_damage(body)
	
func handle_pipe_interaction():
	"""Handle entering pipes"""
	if current_pipe and is_on_floor() and not entering_pipe:
		if Input.is_action_pressed("ui_down"):
			enter_pipe()
			

# ========================================
# PIPE SYSTEM
# ========================================
func enter_pipe():
	"""Execute pipe entrance sequence"""
	if not is_instance_valid(current_pipe) or not is_instance_valid(current_pipe.linked_pipe):
		return

	entering_pipe = true
	velocity = Vector2.ZERO

	var from_pipe = current_pipe
	var to_pipe = current_pipe.linked_pipe

	# Center on entrance pipe
	global_position = from_pipe.center.global_position

	# Enter animation
	pipe_sound.play()
	var enter_tween = create_tween()
	enter_tween.tween_property(
		self,
		"global_position",
		from_pipe.center.global_position + from_pipe.enter_direction * 32,
		0.4
	)

	enter_tween.finished.connect(func():
		# Teleport to exit pipe
		global_position = to_pipe.center.global_position + to_pipe.enter_direction * 32

		# Exit animation
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


# ========================================
# CHECKPOINT SYSTEM
# ========================================
func set_checkpoint(new_spawn_position: Vector2):
	"""Update spawn position when hitting checkpoint"""
	spawn_position = new_spawn_position
	
func respawn():
	"""Respawn player at last checkpoint"""
	if is_respawning:
		return
	
	is_respawning = true
	velocity = Vector2.ZERO
	
	# Teleport to spawn
	global_position = spawn_position
	
	#Reset visual state
	set_visual_state(VisualState.IDLE)
	
	is_respawning = false

# ========================================
# DIE SYSTEM
# ========================================
func die():
	"""Kill Mario and respawn at checkpoint"""
	if is_dead or is_respawning:
		return
	
	is_dead = true
	velocity = Vector2.ZERO
	mario_died.emit()
	death_sound.play()
	
	await death_sound.finished
	is_dead = false
	respawn()
	
func take_damage(from_enemy: Node2D) -> void:
	# 1️⃣ Se já está invencível, ignora
	print("Tentativa de dano - Invencível: ", is_invincible)
	if is_invincible:
		return

	is_invincible = true
	modulate = Color(1, 1, 1, 0.5)  # Semi-transparente

	# 2️⃣ Knockback (empurrão)
	var direction: float = sign(global_position.x - from_enemy.global_position.x)
	velocity.x = direction * 120
	velocity.y = -200

	# 3️⃣ Aqui você pode:
	# - diminuir vida
	# - reduzir tamanho
	# - perder power-up
	print("Mario tomou dano!")

	# 4️⃣ Temporizador de invencibilidade
	var timer := get_tree().create_timer(invincible_time)
	timer.timeout.connect(func():
		is_invincible = false
		modulate = Color.WHITE  # Volta ao normal
	)
