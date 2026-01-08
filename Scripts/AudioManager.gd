extends Node

# ========================================
# AUDIO PLAYERS
# ========================================
@onready var sfx_player := AudioStreamPlayer.new()
@onready var music_player := AudioStreamPlayer.new()

# ========================================
# AUDIO RESOURCES
# ========================================
var sounds := {}
var music := {}

func _ready():
	# Configurar players
	add_child(sfx_player)
	add_child(music_player)
	
	music_player.bus = "Music"
	sfx_player.bus = "SFX"
	
	# Carregar sons (adicione seus caminhos)
	load_sounds()
	
	play_music("level1")

func load_sounds():
	# SFX
	sounds["jump_small"] = preload("res://Sounds/Effects/smb_jump-small.mp3")
	sounds["jump_super"] = preload("res://Sounds/Effects/smb_jump-super.mp3")
	sounds["death"] = preload("res://Sounds/Musics/smb_mariodie.mp3")
	sounds["coin"] = preload("res://Sounds/Effects/smb_coin.mp3")
	sounds["powerup"] = preload("res://Sounds/Effects/smb_1-up.mp3")
	sounds["block"] = preload("res://Sounds/Effects/smb_breakblock.mp3")
	sounds["death"] = preload("res://Sounds/Musics/smb_mariodie.mp3")
	sounds["pipe"] = preload("res://Sounds/Effects/smb_pipe.mp3")
	sounds["kick"] = preload("res://Sounds/Effects/smb_kick.mp3")
	sounds["kiss"] = preload("res://Sounds/Effects/kiss.mp3")
	sounds["down_the_Flagpole"] = preload("res://Sounds/Effects/smb_flagpole.mp3")
	
	# Music
	music["level1"] = preload("res://Sounds/Musics/Theme Song.mp3")
	music["Underground_Theme"] = preload("res://Sounds/Musics/Underground-Theme.mp3")
	music["stage_clear"] = preload("res://Sounds/Musics/smb_stage_clear.mp3")
	music["game_over"] = preload("res://Sounds/Musics/smb_gameover.mp3")
	music["credits"] = preload("res://Sounds/Musics/Credits.mp3")

# ========================================
# PUBLIC FUNCTIONS
# ========================================
func play_sfx(sound_name: String, volume: float = 0.0):
	if sound_name in sounds:
		sfx_player.stream = sounds[sound_name]
		sfx_player.volume_db = volume
		sfx_player.play()


func play_music(music_name: String, loop: bool = true, volume: float = 0.0):
	if music_name in music:
		music_player.stream = music[music_name]
		music_player.stream.loop = loop
		music_player.volume_db = volume
		music_player.play()

func stop_music():
	music_player.stop()

func pause_music():
	music_player.stream_paused = true

func despause():
	music_player.stream_paused = false
