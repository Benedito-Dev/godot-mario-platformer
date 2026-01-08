extends Area2D

@export var linked_pipe: Area2D
@export var enter_direction := Vector2.DOWN
@export var exit_direction := Vector2.UP
@export var pipe_zone: String = "overworld"
@onready var center: Marker2D = $Center

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.current_pipe = self

func _on_body_exited(body):
	if body.is_in_group("player"):
		if body.current_pipe == self:
			body.current_pipe = null
