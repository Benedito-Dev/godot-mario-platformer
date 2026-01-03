extends Node2D

@onready var anim = $Piscada

# Called when the node enters the scene tree for the first time.
func _ready():
	anim.play("Piscada")
