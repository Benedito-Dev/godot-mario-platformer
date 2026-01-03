extends CharacterBody2D

@export var speed := 80.0

var direction := 1

func _physics_process(delta):
	# Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Movimento horizontal
	velocity.x = direction * speed

	move_and_slide()

	# Se bater em parede, inverte
	if is_on_wall():
		direction *= -1

func set_direction(new_direction: int):
	direction = new_direction
