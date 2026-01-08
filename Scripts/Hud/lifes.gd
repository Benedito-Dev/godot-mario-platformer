extends Node2D

@onready var life1 = $life1
@onready var life2 = $life2
@onready var life3 = $life3

@onready var dead_life1 = $dead_life1
@onready var dead_life2 = $dead_life2  
@onready var dead_life3 = $dead_life3

func _ready():
	Game.mario_lives_changed.connect(_on_mario_lives_changed)
	Game.mario_life_gained.connect(_on_mario_life_gained)  # NOVO
	
func _on_mario_lives_changed(lives):
	update_life_display(lives)
	
func _on_mario_life_gained(lives):
	# Feedback visual quando ganha vida (opcional)
	print("Vida ganha! Total: ", lives)
	update_life_display(lives)

func update_life_display(lives):
	# Life 1
	life1.visible = lives >= 3
	dead_life1.visible = lives < 3
	
	# Life 2
	life2.visible = lives >= 2
	dead_life2.visible = lives < 2
	
	# Life 3
	life3.visible = lives >= 1
	dead_life3.visible = lives < 1
