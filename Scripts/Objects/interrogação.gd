extends Node2D

enum ItemType { COIN, MUSHROOM }
enum Direction { LEFT, RIGHT }

@onready var anim = $AnimationPlayer
@onready var deadSprite = $dead
@onready var is_dead = false
@onready var iten_spawn: Marker2D = $iten_spawn

@export var item_type: ItemType = ItemType.COIN
@export var mushroom_direction: Direction = Direction.RIGHT
@export var coin_count: int = 1  # Quantas moedas o bloco tem

var coins_remaining: int  # Contador interno

var coin_scene = preload("res://Scenes/Itens/coin.tscn")
var mushroom_scene = preload("res://Scenes/Itens/Mushroom.tscn")

func _ready():
	deadSprite.visible = false
	anim.play("idle")
	coins_remaining = coin_count  # Inicializa o contador
	
func hit():
	if is_dead == true:
		return
		
	if item_type == ItemType.MUSHROOM or (item_type == ItemType.COIN and coins_remaining == 1):
		anim.play("last_hit")
	
	else:
		anim.play("hit")
	AudioManager.play_sfx("coin")
	
	if item_type == ItemType.MUSHROOM:
		is_dead = true
	
	else:
		coins_remaining -=1
		if coins_remaining <= 0:
			is_dead = true
			
	spawn_item()
	
func spawn_item():
	
	if item_type == ItemType.COIN:
		var item = coin_scene.instantiate()
		item.global_position = iten_spawn.global_position
		item.is_block_coin = true
		get_tree().current_scene.add_child(item)
		
	elif item_type == ItemType.MUSHROOM:
		var item = mushroom_scene.instantiate()
		item.global_position = iten_spawn.global_position
		if item.has_method("set_direction"):
			var direction_value = 1 if mushroom_direction == Direction.RIGHT else -1
			item.set_direction(direction_value)
		get_tree().current_scene.add_child(item)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == 'hit' and is_dead:
		deadSprite.visible = true
