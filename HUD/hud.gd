extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var ThemeSong = $"../ThemeSong"

func _ready():
	Game.coin_collected.connect(_on_coin_collected)
	
	#Conectar aos Sinais do Mario
	var mario = get_node("../Word/Mario")
	mario.mario_died.connect(_on_mario_died)
	mario.mario_entered_pipe.connect(_on_mario_entered_pipe)

func _on_coin_collected(value: int):
	score_label.text = "SCORE %06d" % Game.score

func _on_mario_died():
	ThemeSong.stop()

func _on_mario_entered_pipe():
	ThemeSong.stream_paused = true  # Pausar em vez de parar

func _on_theme_song_finished():
	ThemeSong.play()
