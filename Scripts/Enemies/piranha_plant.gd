extends CharacterBody2D

@onready var timer = $Timer
@onready var detection_area = $Stum_Mario_Area
@onready var Animpiranha_plant = $AnimationPlant

var is_up = false
var mario_nearby = false
var start_position: Vector2
var up_position: Vector2

func _ready():
	detection_area.body_entered.connect(_on_stum_mario_area_body_entered)
	detection_area.body_exited.connect(_on_stum_mario_area_body_exited)
	timer.timeout.connect(_on_timer_timeout)
	Animpiranha_plant.play("atack")
	
	start_position = position
	# Verifica se está rotacionada (invertida)
	var direction = Vector2(0, -32) if rotation_degrees == 0 else Vector2(0, 32)
	up_position = position + direction
	timer.start()

func _on_stum_mario_area_body_entered(body):
	if body.is_in_group("player"):
		mario_nearby = true

func _on_stum_mario_area_body_exited(body):
	if body.is_in_group("player"):
		mario_nearby = false
		
func _on_timer_timeout():
	if not mario_nearby:
		if is_up:
			_go_down()
		else:
			_go_up()
	timer.start()

func _go_up():
	is_up = true
	var tween = create_tween()
	tween.tween_property(self, "position", up_position, 0.5)

func _go_down():
	is_up = false
	var tween = create_tween()
	tween.tween_property(self, "position", start_position, 0.5)

func stomped():
	pass
