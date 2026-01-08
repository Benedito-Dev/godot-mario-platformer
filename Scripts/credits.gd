extends ScrollContainer

@export var text_node : RichTextLabel
@export_range(1,100000,0.1) var credits_time : float = 1
@export_range(1,100000,0.1) var margin_increment : float = 0

@onready var margin : MarginContainer = $MarginContainer

#==========================
#  Animações
#==========================
@onready var Animations = $MarginContainer/AnimationSprites
@onready var AnimationSparkles = $MarginContainer/AnimationSparkles

@onready var KissSprite = $MarginContainer/Kiss
@onready var Mario_Walk_Pipe_Sprite = $"MarginContainer/Mario-Walk"
@onready var Timer_jump = $MarginContainer/Timer_Jump
@onready var Timer_death = $MarginContainer/Timer_death

var animation_triggered = false
var animation_peach = false
var animation_luigi = false
var animation_mario_pipe = false

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var tween = create_tween()
	AnimationSparkles.play("Sparkles")
	Mario_Walk_Pipe_Sprite.visible = false
	
	var text_box_size = text_node.size.y
	
	var window_size = DisplayServer.window_get_size().y
	
	var scroll_amount = ceil(text_box_size * 3/4 + window_size * 2 + margin_increment)
	
	tween.tween_property(
		self,
		"scroll_vertical",
		scroll_amount,
		credits_time
	)
	
	AudioManager.play_music("credits")
	tween.play()

func _process(delta):
	if scroll_vertical >= 750 and not animation_triggered:
		animation_triggered = true
		AudioManager.play_sfx("jump_super", 6.0)
		Animations.play("Mario_jump")
	if scroll_vertical >= 1150 and not animation_peach:
		animation_peach = true
		AudioManager.play_sfx("kiss", 6.0)
		Animations.play("kiss_peach")
		KissSprite.visible = true
	if scroll_vertical >= 1400 and not animation_luigi:
		animation_luigi = true
		Animations.play("Luigi")
	if scroll_vertical >= 2000 and not animation_mario_pipe:
		animation_mario_pipe = true
		Animations.play("Mario_Walk")
		Mario_Walk_Pipe_Sprite.visible = true
		Timer_jump.start()
		Timer_death.start()


func _on_timer_jump_timeout():
	AudioManager.play_sfx("jump_small", 6.0)
	Mario_Walk_Pipe_Sprite.visible = false


func _on_timer_death_timeout():
	AudioManager.play_sfx("death", 6.0)
