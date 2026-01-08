extends Camera2D

var fixed_y: float
@export var target: CharacterBody2D
var is_underground := false

# LIMITES PARA CADA ZONA
var overworld_limits = {"left": -479, "right": 2945 }
var underground_limits = {"left": 224, "right": 656 }

func _ready():
	make_current()
	fixed_y = global_position.y
	Game.zone_changed.connect(_on_zone_changed)
	
	# CONFIGURAR LIMITES INICIAIS (OVERWORLD)
	limit_left = overworld_limits.left
	limit_right = overworld_limits.right

func _process(_delta):
	if target:
		global_position.x = target.global_position.x
		
		if is_underground:
			global_position.y = 462
		else:
			global_position.y = fixed_y

func _on_zone_changed(zone_type: String):
	if zone_type == "underground":
		is_underground = true
		# TROCAR PARA LIMITES DO UNDERGROUND
		limit_left = underground_limits.left
		limit_right = underground_limits.right
	else:
		is_underground = false
		global_position.y = fixed_y
		# TROCAR PARA LIMITES DO OVERWORLD
		limit_left = overworld_limits.left
		limit_right = overworld_limits.right
