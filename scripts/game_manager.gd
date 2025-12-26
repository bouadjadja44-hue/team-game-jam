extends Node

signal noise_changed(new_level: float)
signal objective_updated(text: String)
signal game_over(success: bool)
signal alert_level_changed(level: float)
signal planting_progress_changed(progress: float)

var planting_progress: float = 0.0:
	set(value):
		planting_progress = clamp(value, 0.0, 1.0)
		emit_signal("planting_progress_changed", planting_progress)

var noise_level: float = 0.0:
	set(value):
		noise_level = clamp(value, 0.0, 1.0)
		emit_signal("noise_changed", noise_level)

var alert_level: float = 0.0: # 0.0 to 1.0, enemies attack/chase at 1.0
	set(value):
		alert_level = clamp(value, 0.0, 1.0)
		emit_signal("alert_level_changed", alert_level)

var bomb_planted: bool = false
var tank_destroyed: bool = false
var player_spotted: bool = false
var current_objective: String = "Infiltrate the tank and plant the bomb"

var escape_timer: float = 0.0
const ESCAPE_TIME: float = 10.0 # Time needed to stay silent/hidden to escape

func add_noise(amount: float):
	noise_level += amount

func _process(delta):
	# Gradually decrease noise level
	if noise_level > 0:
		noise_level -= 0.1 * delta # Slightly faster cooldown
	
	# Handle Escape Logic
	if alert_level > 0:
		if not player_spotted and noise_level < 0.2:
			escape_timer += delta
			if escape_timer >= ESCAPE_TIME:
				alert_level = 0.0
				escape_timer = 0.0
				emit_signal("objective_updated", "You've escaped the detection! Return to the mission")
		else:
			escape_timer = 0.0
	
	if alert_level >= 1.0 and not player_spotted:
		player_spotted = true
		emit_signal("objective_updated", "YOU ARE SPOTTED! RUN!")

func plant_bomb():
	if bomb_planted: return
	bomb_planted = true
	current_objective = "Bomb Planted! ESCAPE BEFORE THE EXPLOSION!"
	emit_signal("objective_updated", current_objective)
	# Explosion after 5 seconds
	await get_tree().create_timer(5.0).timeout
	tank_destroyed = true
	emit_signal("objective_updated", "Tank Destroyed! Reach the Safe Zone to finish")

func reach_safe_zone():
	if tank_destroyed:
		emit_signal("game_over", true)
