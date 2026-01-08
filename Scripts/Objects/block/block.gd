extends StaticBody2D

@export var piece_scene: PackedScene

func hit():
	AudioManager.play_sfx("block")
	break_brick()

func break_brick():
	# Criar 4 pedaços
	for i in range(4):
		var piece = piece_scene.instantiate()
		get_parent().add_child(piece)
		
		# Posicionar no centro do tijolo
		piece.global_position = global_position
		
		# Aplicar impulsos diferentes para cada pedaço
		var impulse = Vector2()
		match i:
			0: impulse = Vector2(-100, -200)  # Cima-esquerda
			1: impulse = Vector2(100, -200)   # Cima-direita  
			2: impulse = Vector2(-80, -100)   # Baixo-esquerda
			3: impulse = Vector2(80, -100)    # Baixo-direita
		
		piece.apply_impulse(impulse)
	
	# Remover tijolo original
	queue_free()
