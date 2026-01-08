extends Area2D

@export var checkpoint_id: String = ""
var activated: bool = false
@onready var Bowser_Flag = $"Flag-Bowser"
@onready var Mario_Flag = $"Flag-Mario"
@onready var anim_Flag = $AnimationFlag

func _ready():
	body_entered.connect(_on_body_entered)
	anim_Flag.play("Bowser-Flag")

func _on_body_entered(body):
	if body.is_in_group("player") and not activated:
		activated = true
		Bowser_Flag.visible = false
		Mario_Flag.visible = true
		anim_Flag.play("Mario-Flag")
		
		# Agora só o Game gerencia checkpoint
		Game.activate_checkpoint(checkpoint_id, global_position)
