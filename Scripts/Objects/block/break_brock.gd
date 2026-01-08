extends RigidBody2D

@onready var break_brock = $break_brock
var blink_timer := 0.0
var blink_duration := 1.0
var blink_speed := 0.1

func _ready() -> void:
	# Timer para começar a piscar após 1 segundo
	get_tree().create_timer(1.0).timeout.connect(start_blinking)

func _process(delta: float) -> void:
	if blink_timer > 0:
		blink_timer -= delta
		
		# Piscar alternando visibilidade
		var blink_cycle = fmod(blink_timer, blink_speed * 2)
		break_brock.visible = blink_cycle < blink_speed
		
		# Sumir quando acabar o tempo
		if blink_timer <= 0:
			queue_free()

func start_blinking():
	blink_timer = blink_duration
