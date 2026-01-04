extends Node2D

enum ItemType { COIN, MUSHROOM }
enum Direction { LEFT, RIGHT }

@onready var anim = $AnimationPlayer
@onready var deadSprite = $dead
@onready var is_dead = false
@onready var iten_spawn: Marker2D = $iten_spawn

@export var item_type: ItemType = ItemType.COIN
@export var mushroom_direction: Direction = Direction.RIGHT

var coin_scene = preload("res://Scenes/Itens/coin.tscn")
var mushroom_scene = preload("res://Scenes/Itens/Mushroom.tscn")

func _ready():
	deadSprite.visible = false
	anim.play("idle")
	
func hit():
	if is_dead == true:
		return
	anim.play("hit")
	AudioManager.play_sfx("coin")
	
	spawn_item()
	
func spawn_item():
	var item_scene = coin_scene if item_type == ItemType.COIN else mushroom_scene
	
	var item = item_scene.instantiate()
	item.global_position = iten_spawn.global_position
	
	if item_type == ItemType.MUSHROOM and item.has_method("set_direction"):
		var direction_value = 1 if mushroom_direction == Direction.RIGHT else -1
		item.set_direction(direction_value)
	
	get_tree().current_scene.add_child(item)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == 'hit':
		deadSprite.visible = true
		is_dead = true
