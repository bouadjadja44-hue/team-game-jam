extends CharacterBody3D

@export var speed: float = 3.5
@export var detection_range: float = 20.0
@export var field_of_view: float = 90.0 # degrees

@onready var vision_ray: RayCast3D = RayCast3D.new()

var target_player: CharacterBody3D = null
var last_known_position: Vector3 = Vector3.ZERO
var state: String = "patrol" # patrol, chase, search

func _ready():
	add_child(vision_ray)
	vision_ray.enabled = true
	# Vision ray should only hit player and environment
	vision_ray.set_collision_mask_value(1, true)
	
func _physics_process(delta):
	if not target_player:
		target_player = get_tree().get_first_node_in_group("player")
		return

	match state:
		"patrol":
			check_for_player()
		"chase":
			move_towards(target_player.global_position, delta)
			if global_position.distance_to(target_player.global_position) > detection_range * 1.5:
				state = "search"
				last_known_position = target_player.global_position
		"search":
			move_towards(last_known_position, delta)
			if global_position.distance_to(last_known_position) < 1.0:
				await get_tree().create_timer(2.0).timeout
				state = "patrol"
			check_for_player()

	# If player is making too much noise nearby, investigate
	if GameManager.noise_level > 0.5 and global_position.distance_to(target_player.global_position) < detection_range:
		state = "chase"

func check_for_player():
	var dir_to_player = global_position.direction_to(target_player.global_position)
	var angle = rad_to_deg(transform.basis.z.angle_to(dir_to_player))
	
	if angle < field_of_view / 2 and global_position.distance_to(target_player.global_position) < detection_range:
		vision_ray.target_position = target_player.global_position - global_position
		vision_ray.force_raycast_update()
		
		if vision_ray.is_colliding() and vision_ray.get_collider().is_in_group("player"):
			var visibility = target_player.get("visibility_level") if target_player.get("visibility_level") else 1.0
			# Harder to see if crouching
			if visibility > 0.5 or global_position.distance_to(target_player.global_position) < 5.0:
				state = "chase"
				GameManager.alert_level += 0.1 # Increase alert globally

func move_towards(pos: Vector3, delta: float):
	var dir = global_position.direction_to(pos)
	dir.y = 0
	velocity = dir * speed
	if dir.length() > 0.1:
		look_at(global_position + dir, Vector3.UP)
	move_and_slide()
	
	# If close enough to attack
	if global_position.distance_to(target_player.global_position) < 2.0 and state == "chase":
		GameManager.emit_signal("game_over", false)
