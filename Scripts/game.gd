extends Node2D
# (pode ser Node simples também, mas Node2D não quebra nada)

signal coin_collected(value: int)
signal score_changed(score: int)
signal coins_changed(coins: int)

var score: int = 0
var coins: int = 0

var current_checkpoint_id: String = ""
var checkpoints_activated: Array[String] = []

func collect_coin(value: int):
	coins += 1
	score += value

	emit_signal("coin_collected", value)
	emit_signal("coins_changed", coins)
	emit_signal("score_changed", score)

func activate_checkpoint(checkpoint_id: String, position: Vector2):
	if checkpoint_id not in checkpoints_activated:
		checkpoints_activated.append(checkpoint_id)
	current_checkpoint_id = checkpoint_id
