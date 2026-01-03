extends Camera2D

var fixed_y: float
@export var target: CharacterBody2D

func _ready():
	make_current()
	fixed_y = global_position.y

func _process(_delta):
	if target:
		global_position.x = target.global_position.x
