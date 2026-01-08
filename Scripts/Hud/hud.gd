extends CanvasLayer

@onready var score_label: Label = $ScoreLabel

func _ready():
	Game.coin_collected.connect(_on_coin_collected)
	Game.score_changed.connect(_on_score_changed)

func _on_coin_collected(value: int):
	score_label.text = "SCORE %06d" % Game.score

func _on_score_changed(new_score: int):
	score_label.text = "SCORE %06d" % new_score
