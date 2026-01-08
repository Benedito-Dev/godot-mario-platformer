extends Node2D

# ========================================
# SIGNALS
# ========================================
signal coin_collected(value: int)
signal score_changed(score: int)
signal coins_changed(coins: int)
signal mario_lives_changed(lives: int)
signal mario_life_gained(lives: int)
signal level_completed
signal game_over()

# ========================================
# GAME STATE
# ========================================
var score: int = 0
var coins: int = 0
var current_zone := "overworld"

# ========================================
# KONAMI CODE EASTER EGG
# ========================================
var konami_code = ["ui_up", "ui_up", "ui_down", "ui_down", "ui_left", "ui_right", "ui_left", "ui_right", "b", "a"]
var current_sequence = []

# ========================================
# CHECKPOINT SYSTEM
# ========================================
var current_checkpoint_id: String = ""
var checkpoints_activated: Array[String] = []

# ========================================
# MARIO MANAGEMENT
# ========================================
var mario_lives: int = 3
var mario_spawn_position: Vector2 = Vector2.ZERO
var mario_current_powerup: PowerUpType = PowerUpType.SMALL
var mario_is_invincible: bool = false
var mario_is_dead: bool = false
var mario_is_respawning: bool = false

var mario: CharacterBody2D

# ========================================
# ENUMS
# ========================================
enum PowerUpType {
	SMALL,
	SUPER,
	FIRE,
	SUPER_MUSHROOM,
	FIRE_FLOWER,
	START,
	ONE_UP_MUSHROOM
}

# ========================================
# ZONE SYSTEM 
# ========================================
signal zone_changed(zone_type: String)

# ========================================
# INPUT HANDLING
# ========================================
func _input(event):
	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") or \
	   event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right") or \
	   event.is_action_pressed("b") or event.is_action_pressed("a"):
		
		var action = ""
		if event.is_action_pressed("ui_up"): action = "ui_up"
		elif event.is_action_pressed("ui_down"): action = "ui_down"
		elif event.is_action_pressed("ui_left"): action = "ui_left"
		elif event.is_action_pressed("ui_right"): action = "ui_right"
		elif event.is_action_pressed("b"): action = "b"
		elif event.is_action_pressed("a"): action = "a"
		
		current_sequence.append(action)
		
		if current_sequence.size() > konami_code.size():
			current_sequence.pop_front()
		
		if current_sequence == konami_code:
			get_tree().change_scene_to_file("res://Scenes/UI/credits.tscn")

# ========================================
# REGISTER MARIO
# ========================================
func register_mario(mario_node: CharacterBody2D):
	mario = mario_node
	mario_spawn_position = mario.global_position
	connect_mario_signals()

# ========================================
# MARIO SIGNAL CONNECTIONS
# ========================================
func connect_mario_signals():
	mario.mario_died.connect(_on_mario_died)
	mario.fell_off_world.connect(_on_mario_fell_off_world)
	mario.damage_received.connect(_on_mario_damage_received)
	mario.enemy_stomped.connect(_on_mario_enemy_stomped)
	mario.block_hit.connect(_on_mario_block_hit)
	# Adicionar mais conexões conforme implementarmos os novos sinais
	
	#Conectando Sinais do Jogo
	level_completed.connect(_on_level_completed)
	
# ========================================
# POINTS SYSTEM
# ========================================
func collect_points(value: int):
	score += value
	emit_signal("score_changed", score)

# ========================================
# CHECKPOINT SYSTEM
# ========================================
func activate_checkpoint(checkpoint_id: String, position: Vector2):
	if checkpoint_id not in checkpoints_activated:
		checkpoints_activated.append(checkpoint_id)
	current_checkpoint_id = checkpoint_id
	mario_spawn_position = position
	
# ========================================
# Level SYSTEM
# ========================================
func _on_level_completed():
	AudioManager.play_music("stage_clear", false)

func start_castle_walk():
	print("Andando ate o castelo")
	mario.is_walk_to_castle = true
	mario.set_physics_process(true)
	
	for sprite in mario.sprites.values():
		sprite.visible = false
	mario.sprites.walk.visible = true
	mario.sprites.walk.flip_h = false
	mario.anim_mario.play("walk")
	
	mario.velocity.x = 55
	mario.velocity.y = 0
	
	var tween = create_tween()
	
	# 1. Anda por 3.4 segundos
	tween.tween_interval(3.3)
	
	# 2. Para e muda para idle
	tween.tween_callback(func():
		mario.velocity.x = 0
		mario.anim_mario.stop()
		mario.sprites.walk.visible = false
		mario.sprites.idle.visible = true
	)
	
	# 3. Espera um pouco parado
	tween.tween_interval(0.5)
	
	# 4. Muda para victory
	tween.tween_callback(func():
		mario.sprites.idle.visible = false
		mario.sprites.victory.visible = true  # VOCÊ PRECISA ADICIONAR ESTA SPRITE
	)
	
	# 5. Espera na victory
	tween.tween_interval(1)
	
	# 6. Volta a andar
	tween.tween_callback(func():
		mario.sprites.victory.visible = false
		mario.sprites.walk.visible = true
		mario.anim_mario.play("walk")
		mario.velocity.x = 55
	)
	
	# 7. Anda mais meio segundo e desaparece
	tween.tween_interval(0.5)
	tween.tween_callback(func():
		mario.visible = false
	)

# ========================================
# ZONE MANAGEMENT
# ========================================
func change_zone(new_zone: String):
	if current_zone != new_zone:
		current_zone = new_zone
		zone_changed.emit(new_zone)
		
		match new_zone:
			"underground":
				AudioManager.play_music("Underground_Theme")
			"overworld":
				AudioManager.play_music("level1")

func get_current_zone() -> String:
	return current_zone
	
func get_death_y_limit() -> float:
	match current_zone:
		"overworld":
			return 260.0  # Limite do overworld
		"underground":
			return 2000.0  # Limite do underground (mais baixo)
		_:
			return 600.0  # Padrão
	
# ========================================
# MARIO LIFE SYSTEM
# ========================================
func mario_gain_life():
	mario_lives += 1
	emit_signal("mario_life_gained", mario_lives)
	emit_signal("mario_lives_changed", mario_lives)  # Para atualizar HUD também
	
# ========================================
# MARIO MANAGEMENT FUNCTIONS
# ========================================
func mario_take_damage(from_enemy: Node2D):
	if mario_is_invincible or mario_is_dead:
		return
	
	mario_is_invincible = true
	mario.set_visual_state(mario.VisualState.DAMAGE)
	
	mario_lives -= 1
	emit_signal("mario_lives_changed", mario_lives)
	
	# Knockback
	var direction: float = sign(mario.global_position.x - from_enemy.global_position.x)
	mario.velocity.x = direction * 120
	mario.velocity.y = -200
	
	# Flip sprite de dano baseado no knockback
	mario.sprites.damage.flip_h = direction > 0  # Se knockback vai pra direita
	
	# Piscar sprite
	var blink_tween = create_tween()
	blink_tween.set_loops(10)  # 10 piscadas em 1 segundo
	blink_tween.tween_method(_blink_sprite, 0, 1, 0.1)
	
	# Timer de invencibilidade
	var timer := get_tree().create_timer(1.0)
	timer.timeout.connect(func():
		blink_tween.kill()
		mario_is_invincible = false
		mario.visible = true
		mario.set_visual_state(mario.VisualState.IDLE)
	)
	
func _blink_sprite(value):
	mario.visible = value < 0.5

func mario_die():
	if mario_is_dead or mario_is_respawning:
		return
	
	mario_is_dead = true
	mario_lives -= 1
	emit_signal("mario_lives_changed", mario_lives)
	
	mario.velocity = Vector2.ZERO
	AudioManager.pause_music()
	AudioManager.play_sfx("death")
	
	if mario_lives <= 0:
		await get_tree().create_timer(2.8).timeout  # Aguarda som terminar
		emit_signal("game_over")
		get_tree().change_scene_to_file("res://Scenes/UI/Game_Over.tscn")
	else:
		await get_tree().create_timer(2.7).timeout  # Aguarda som terminar
		mario_respawn()

func mario_respawn():
	if mario_is_respawning:
		return
	
	AudioManager.despause()
	
	mario_is_respawning = true
	mario_is_dead = false
	
	# Teleportar para spawn
	mario.global_position = mario_spawn_position
	mario.velocity = Vector2.ZERO
	mario.set_visual_state(mario.VisualState.IDLE)
	
	mario_is_respawning = false

func mario_collect_powerup(powerup_type: PowerUpType):
	mario_current_powerup = powerup_type
	
	if powerup_type == PowerUpType.ONE_UP_MUSHROOM:
		if mario_lives == 3:
			score +=300
			emit_signal("score_changed", score)
		else:
			mario_gain_life()
	
	print("Mario coletou PowerUp: ", powerup_type)

# ========================================
# MARIO SIGNAL HANDLERS
# ========================================
func _on_mario_fell_off_world():
	mario_die()
	
func _on_mario_damage_received(from_enemy: Node2D):
	mario_take_damage(from_enemy)

func _on_mario_enemy_stomped(enemy):
	score +=100
	print("Mais 100 pontos para o Mario")
	emit_signal("score_changed", score)

func _on_mario_block_hit(block: Node2D):
	print("Mario bateu no bloco: ", block.name)

func _on_mario_died():
	mario_die()
