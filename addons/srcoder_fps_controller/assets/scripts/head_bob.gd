extends Node3D

# Head bobbing parameters
@export_group("Head Bobbing Settings")
@export var bob_amount : float = 0.02  # Amount of bobbing movement (reduced)
@export var bob_speed : float = 6.0    # Speed of bobbing when walking (reduced)
@export var idle_bob_amount : float = 0.005  # Amount of idle movement (reduced)
@export var idle_bob_speed : float = 1.5    # Speed of idle movement (reduced)
@export var bob_smoothing : float = 15.0    # How quickly to transition between states (increased)

# Internal variables
var time : float = 0.0
var current_bob_amount : float = 0.0
var target_bob_amount : float = 0.0
var current_bob_speed : float = 0.0
var target_bob_speed : float = 0.0

# Original position
var original_position : Vector3

func _ready():
	# Store the original position
	original_position = position

func _process(delta):
	# Update time
	time += delta
	
	# Get player movement state
	var player = get_parent().get_parent()
	var is_moving = false
	var is_on_ground = false
	
	if player.has_method("is_on_floor"):
		is_on_ground = player.is_on_floor()
		var velocity = player.velocity if "velocity" in player else Vector3.ZERO
		var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
		is_moving = horizontal_velocity.length() > 0.1 and is_on_ground
	
	# Set target bobbing values based on movement state
	if is_moving:
		target_bob_amount = bob_amount
		target_bob_speed = bob_speed
	else:
		target_bob_amount = idle_bob_amount
		target_bob_speed = idle_bob_speed
	
	# Smooth transition between states
	current_bob_amount = move_toward(current_bob_amount, target_bob_amount, bob_smoothing * delta)
	current_bob_speed = move_toward(current_bob_speed, target_bob_speed, bob_smoothing * delta)
	
	# Calculate bobbing offset
	var bob_offset = Vector3.ZERO
	
	if current_bob_amount > 0.001:
		# Head bobbing using gentle sine waves for subtle movement
		bob_offset.x = sin(time * current_bob_speed) * current_bob_amount * 0.3  # Reduced X movement
		bob_offset.y = abs(sin(time * current_bob_speed * 1.5)) * current_bob_amount  # Gentler Y movement
		bob_offset.z = cos(time * current_bob_speed * 0.3) * current_bob_amount * 0.2  # Reduced Z movement
	
	# Apply the bobbing to position
	position = original_position + bob_offset
