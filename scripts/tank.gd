extends StaticBody3D

@export var detection_range: float = 20.0
@export var detection_speed: float = 0.5
@export var explosion_scene: PackedScene = preload("res://scenes/explosion_effect.tscn")

var detected_level: float = 0.0
var interaction_area: Area3D

func _ready():
	add_to_group("objective")
	
	# Interaction Area for planting bomb
	interaction_area = Area3D.new()
	var coll = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(4, 4, 4)
	coll.shape = box
	interaction_area.add_child(coll)
	add_child(interaction_area)

func _process(delta):
	var player = get_tree().get_first_node_in_group("player")
	if not player: 
		return

	if GameManager.tank_destroyed:
		if is_visible_in_tree():
			# Trigger explosion first
			spawn_explosion()
			# Wait a tiny fraction for the flash to cover the tank
			await get_tree().create_timer(0.1).timeout
			hide() # Hide the tank mesh
			# Disable collision
			if has_node("CollisionShape3D"):
				$CollisionShape3D.disabled = true
		return

	# Detection logic
	var dist = global_position.distance_to(player.global_position)
	
	# Handle Bomb Planting - Check distance directly
	if not GameManager.bomb_planted and dist < 5.0:
		if Input.is_key_pressed(KEY_E) or Input.is_action_pressed("interact"):
			GameManager.planting_progress += delta * 0.33 # Takes 3 seconds
			GameManager.add_noise(0.05 * delta)
			if GameManager.planting_progress >= 1.0:
				GameManager.plant_bomb()
				GameManager.planting_progress = 0.0
		else:
			GameManager.planting_progress = max(0.0, GameManager.planting_progress - delta * 2.0)
	else:
		if GameManager.planting_progress > 0:
			GameManager.planting_progress = 0.0

	# AI Alert logic
	if dist < detection_range:
		var noise = GameManager.noise_level
		var visibility = player.get("visibility_level") if player.get("visibility_level") else 1.0
		var dist_factor = 1.0 - (dist / detection_range)
		detected_level += (noise + (visibility * 0.2)) * dist_factor * delta * detection_speed
		
		if detected_level >= 1.0:
			GameManager.alert_level = 1.0
	else:
		detected_level = max(0.0, detected_level - delta * 0.1)

func spawn_explosion():
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		get_parent().add_child(explosion)
		explosion.global_position = global_position
		# Start emitting
		for child in explosion.get_children():
			if child is GPUParticles3D:
				child.emitting = true
		
		# Shake Camera
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var cam = player.get_node_or_null("CameraPivot/Camera3D")
			if cam and global_position.distance_to(player.global_position) < 30.0:
				shake_camera(cam)

		# Auto queue free after 3 seconds
		await get_tree().create_timer(3.0).timeout
		explosion.queue_free()

func shake_camera(cam):
	var original_pos = cam.position
	for i in range(15):
		cam.position = original_pos + Vector3(randf_range(-0.2, 0.2), randf_range(-0.2, 0.2), 0)
		await get_tree().create_timer(0.02).timeout
	cam.position = original_pos
