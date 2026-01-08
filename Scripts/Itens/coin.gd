extends Node2D

@export var value := 10
@export var jump_height := 32
@export var up_time := 0.25
@export var down_time := 0.2
@export var is_block_coin := true  # <- NOVA VARIÁVEL

@onready var anim_coin = $Coin_Animator
@onready var Area_collected = $Collected
@onready var coins = 0

func _ready():
	anim_coin.play("idle")

	if is_block_coin:
		_animate_jump()
	else:
		Area_collected.body_entered.connect(_on_collected_body_entered)

func _animate_jump():
	var start_pos := position
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(self, "position:y", start_pos.y - jump_height, up_time)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y", start_pos.y, down_time)

	tween.finished.connect(_on_coin_finished)

func _on_collected_body_entered(body):
	if body.is_in_group("player"):
		AudioManager.play_sfx("coin")
		coins += 1
		Game.collect_points(value)
		Game.emit_signal("coins_changed", Game.coins)
		queue_free()

func _on_coin_finished():
	coins += 1
	Game.collect_points(value)
	Game.emit_signal("coins_changed", Game.coins)
	queue_free()
