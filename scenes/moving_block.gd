extends Node2D

var active = false
var moving_down = true
var starting_position = Vector2(0,0)

func _ready() -> void:
	starting_position = global_position

func _physics_process(delta: float) -> void:
	if moving_down and $"../Timer".is_stopped():
		if global_position.y < $"../Marker2D".global_position.y:
			global_position.y += 80 * delta
		if global_position.y >= $"../Marker2D".global_position.y:
			global_position.y = $"../Marker2D".global_position.y
			moving_down = false
			$"../Timer".start()
	elif not moving_down and $"../Timer".is_stopped():
		if global_position.y > starting_position.y:
			global_position.y -= 60 * delta
		if global_position.y <= starting_position.y:
			global_position.y = starting_position.y
			moving_down = true
			$"../Timer".start()
