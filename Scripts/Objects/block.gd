extends StaticBody2D

func hit():
	AudioManager.play_sfx("block")
	queue_free()
