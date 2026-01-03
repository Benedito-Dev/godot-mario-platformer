extends CharacterBody2D

# =======================
# CONSTANTES
# =======================
const SPEED := 20.0

# =======================
# NODES
# =======================
@onready var anim_goomba = $AnimationGoomba
@onready var Goomba = $Goomba
@onready var GoombaStomped = $Stomped
@onready var StumSound = $Stum_sound

# =======================
# ESTADO
# =======================
@export var direction := -1  # -1 = esquerda | 1 = direita

func _ready() -> void:
	anim_goomba.play("Walkings")
	_update_flip()

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_move()
	move_and_slide()
	_check_wall_collision()

# =======================
# FÍSICA
# =======================
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

func _move() -> void:
	velocity.x = direction * SPEED

# =======================
# COLISÃO COM PAREDE
# =======================
func _check_wall_collision() -> void:
	if is_on_wall():
		direction *= -1
		_update_flip()

# =======================
# VISUAL
# =======================
func _update_flip() -> void:
	# Se direction < 0 → olha para esquerda
	Goomba.flip_h = direction > 0

# =======================
# STUM
# =======================
func stomped():
	StumSound.play()
	Goomba.visible = false
	Goomba2.visible = false
	GoombaStomped.flip_h = direction > 0
	GoombaStomped.visible = true
	anim_goomba.play("Stomp")
	await StumSound.finished


func _on_animation_goomba_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Stomp":
		queue_free()
