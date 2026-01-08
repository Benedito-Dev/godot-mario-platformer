extends CharacterBody2D

# =======================
# CONSTANTES
# =======================
const SPEED := 20.0

# =======================
# NODES
# =======================
@onready var anim_Koopa = $AnimationKoopa
@onready var Koopa = $Koopa
@onready var Koopa_Turn = $Turn
@onready var ground_check = $RayCast2D

# =======================
# ESTADO
# =======================
@export var direction := -1
var is_turning = false

func _ready() -> void:
	anim_Koopa.play("Walking")
	_update_flip()

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_move()
	move_and_slide()
	_check_wall_collision()
	_check_cliff()

# =======================
# FÍSICA
# =======================
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

func _move() -> void:
	velocity.x = direction * SPEED

# =======================
# COLISÕES
# =======================
func _check_wall_collision() -> void:
	if is_on_wall() and not is_turning:
		_turn_around()
		
func _check_cliff() -> void:
	if is_on_floor() and not ground_check.is_colliding() and not is_turning:
		_turn_around()
		
# =======================
# VIRADA
# =======================
func _turn_around():
	is_turning = true
	velocity.x = 0
	
	Koopa.visible = false
	Koopa_Turn.visible = true
	
	await get_tree().create_timer(0.2).timeout
	
	direction *= -1
	
	Koopa_Turn.visible = false
	Koopa.visible = true
	_update_flip()
	
	await get_tree().process_frame
	
	is_turning = false
	anim_Koopa.play("Walking")

# =======================
# VISUAL
# =======================
func _update_flip() -> void:
	Koopa.flip_h = direction > 0
	ground_check.position.x = 8 * direction

# =======================
# STOMP
# =======================
func stomped():
	AudioManager.play_sfx("kick")
	queue_free()

func _on_animation_goomba_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Stomp":
		queue_free()
