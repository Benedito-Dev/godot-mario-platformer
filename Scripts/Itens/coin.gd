extends Sprite2D

@export var value := 100
@export var jump_height := 32
@export var up_time := 0.25
@export var down_time := 0.2

@onready var anim_coin = $"../Coin_Animator"

func _ready():
	anim_coin.play("idle")

	var start_pos := position
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(self, "position:y", start_pos.y - jump_height, up_time)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y", start_pos.y, down_time)

	tween.finished.connect(_on_coin_finished)

func _on_coin_finished():
	Game.collect_coin(value)
	queue_free()
