extends Node2D

# ========================================
# SIGNALS
# ========================================
signal coin_collected(value: int)
signal score_changed(score: int)
signal coins_changed(coins: int)
signal mario_lives_changed(lives: int)
signal game_over()

# ========================================
# GAME STATE
# ========================================
var score: int = 0
var coins: int = 0

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

# ========================================
# COIN SYSTEM
# ========================================
func collect_coin(value: int):
	coins += 1
	score += value

	emit_signal("coin_collected", value)
	emit_signal("coins_changed", coins)
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
# MARIO MANAGEMENT FUNCTIONS
# ========================================
func mario_take_damage(from_enemy: Node2D):
	if mario_is_invincible or mario_is_dead:
		return
	
	mario_is_invincible = true
	mario.modulate = Color(1, 1, 1, 0.5)
	
	# Knockback
	var direction: float = sign(mario.global_position.x - from_enemy.global_position.x)
	mario.velocity.x = direction * 120
	mario.velocity.y = -200
	
	# Timer de invencibilidade
	var timer := get_tree().create_timer(1.0)
	timer.timeout.connect(func():
		mario_is_invincible = false
		mario.modulate = Color.WHITE
	)

func mario_die():
	if mario_is_dead or mario_is_respawning:
		return
	
	mario_is_dead = true
	mario_lives -= 1
	emit_signal("mario_lives_changed", mario_lives)
	
	mario.velocity = Vector2.ZERO
	AudioManager.play_sfx("death")
	
	if mario_lives <= 0:
		await get_tree().create_timer(2.7).timeout  # Aguarda som terminar
		emit_signal("game_over")
	else:
		await get_tree().create_timer(2.7).timeout  # Aguarda som terminar
		mario_respawn()

func mario_respawn():
	if mario_is_respawning:
		return
	
	mario_is_respawning = true
	mario_is_dead = false
	
	# Teleportar para spawn
	mario.global_position = mario_spawn_position
	mario.velocity = Vector2.ZERO
	mario.set_visual_state(mario.VisualState.IDLE)
	
	mario_is_respawning = false

func mario_collect_powerup(powerup_type: PowerUpType):
	mario_current_powerup = powerup_type
	print("Mario coletou PowerUp: ", powerup_type)

# ========================================
# MARIO SIGNAL HANDLERS
# ========================================
func _on_mario_fell_off_world():
	mario_die()
	
func _on_mario_damage_received(from_enemy: Node2D):
	mario_take_damage(from_enemy)

func _on_mario_enemy_stomped(enemy: Node2D):
	score +=200
	emit_signal("score_changed", score)

func _on_mario_block_hit(block: Node2D):
	print("Mario bateu no bloco: ", block.name)

func _on_mario_died():
	mario_die()
