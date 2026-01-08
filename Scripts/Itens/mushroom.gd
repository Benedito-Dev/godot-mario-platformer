extends CharacterBody2D

@export var speed := 60.0

var direction := 1
var type = Game.PowerUpType.ONE_UP_MUSHROOM
@onready var animMushroom = $AnimationMushroom

func _ready():
	animMushroom.play("idle")

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

	velocity.x = direction * speed
	move_and_slide()

	if is_on_wall():
		direction *= -1

func _on_area_power_up_body_entered(body):
	if body.is_in_group("player"):

		AudioManager.play_sfx("powerup")

		# Agora chama diretamente o Game ao invés do Mario
		Game.mario_collect_powerup(type)

		queue_free()
