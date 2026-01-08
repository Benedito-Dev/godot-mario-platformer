extends Area2D

@onready var flag = $Flag
@onready var slide_point = $SlidePoint
@onready var bottom_point = $BottomPoint
@onready var AnimationFlag = $AnimationFlag

var mario_sliding = false

func _ready():
	AnimationFlag.play("idle")

func _on_body_entered(body):
	if body.is_in_group("player") and not mario_sliding:
		mario_sliding = true
		_start_flag_sequence(body)

func _start_flag_sequence(mario):
	mario.set_physics_process(false)
	mario.start_flag_sliding()
	mario.global_position = slide_point.global_position
	AudioManager.play_sfx("down_the_Flagpole")
	_slide_mario_and_flag(mario)

func _slide_mario_and_flag(mario):
	var tween = create_tween()
	tween.parallel().tween_property(mario, "global_position", bottom_point.global_position, 2.0)
	tween.parallel().tween_property(flag, "global_position:y", bottom_point.global_position.y, 2.0)
	tween.finished.connect(_on_slide_finished.bind(mario))
	
func _on_slide_finished(mario):
	mario.stop_flag_sliding()
	Game.start_castle_walk()
	Game.level_completed.emit()
