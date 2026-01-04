extends Area2D

@export var checkpoint_id: String = ""
var activated: bool = false
@onready var Bowser_Flag = $"Flag-Bowser"
@onready var Mario_Flag = $"Flag-Mario"

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") and not activated:
		activated = true
		Bowser_Flag.visible = false
		Mario_Flag.visible = true
		
		# Agora só o Game gerencia checkpoint
		Game.activate_checkpoint(checkpoint_id, global_position)
