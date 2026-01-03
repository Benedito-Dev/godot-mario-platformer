extends StaticBody2D

@onready var SoundBrake = $Brake

func hit():
	SoundBrake.play()
	await SoundBrake.finished
	queue_free()
