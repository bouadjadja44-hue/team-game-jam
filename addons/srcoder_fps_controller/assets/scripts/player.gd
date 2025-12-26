extends CharacterBody3D




@onready var footstep_audio: Node3D = $CameraPivot/FootstepAudio





## The movement speed in m/s. Default is 5.
@export_range(1.0,30.0) var speed : float = 5.0
## The Jump Velocity in m/s- default to 6.0
@export_range(2.0,10.0) var jump_velocity : float = 6.0

## Mouse sensitivity for looking around. Default is 3.0
@export_range(1.0,5.0) var mouse_sensitivity = 3.0
## Mouse smoothing factor. Higher values = more smoothing. Default is 5.0
@export_range(1.0,10.0) var mouse_smoothing = 5.0
var mouse_motion : Vector2 = Vector2.ZERO
var smooth_mouse_motion : Vector2 = Vector2.ZERO
var pitch = 0

## The amount of acceleration on the ground- less feels floaty, more is snappy-[br]Default is 4
@export_range(1.0,10.0) var ground_acceleration := 4.0
## the amount of acceleration when in the air. less feels more floaty more is more snappy.[br]Default is 0.5
@export_range(0.0,5.0) var air_acceleration := 0.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
@export_range(5.0,25.0) var gravity : float = 15.0

# the camera pivot for head pitch movement
@onready var camera_pivot : Node3D = $CameraPivot

func _ready():
	add_to_group("player")
	
	# Setup Raycasts for climbing
	head_ray.target_position = Vector3(0, 0, -1.0)
	head_ray.position = Vector3(0, 1.8, 0) # Near eyes
	chest_ray.target_position = Vector3(0, 0, -1.0)
	chest_ray.position = Vector3(0, 1.0, 0) # Near chest
	add_child(head_ray)
	add_child(chest_ray)
	head_ray.enabled = true
	chest_ray.enabled = true

signal noise_generated(amount: float)

var noise_level: float = 0.0
var is_running: bool = false
var is_crouching: bool = false
@export var run_speed: float = 8.0
@export var walk_speed: float = 5.0
@export var crouch_speed: float = 2.0

var visibility_level: float = 1.0 # 1.0 = visible, 0.5 = crouching

# Parkour Variables
var is_climbing: bool = false
@onready var head_ray: RayCast3D = RayCast3D.new()
@onready var chest_ray: RayCast3D = RayCast3D.new()

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor() and not is_climbing:
		velocity.y -= gravity * delta

	# Parkour Logic
	handle_parkour(delta)
	
	if is_climbing:
		return # Skip normal movement if climbing

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		GameManager.add_noise(0.20) # 20% noise for jumping

	# Handle Running and Crouching
	if Input.is_action_pressed("shift") and not is_crouching:
		is_running = true
		speed = run_speed
	else:
		is_running = false
		
	if Input.is_action_pressed("ctrl"): # Assuming ctrl for crouch
		is_crouching = true
		speed = crouch_speed
		camera_pivot.position.y = move_toward(camera_pivot.position.y, 0.5, delta * 5)
		visibility_level = 0.5
	else:
		is_crouching = false
		camera_pivot.position.y = move_toward(camera_pivot.position.y, 1.7, delta * 5) # Default height
		visibility_level = 1.0

	if not is_running and not is_crouching:
		speed = walk_speed

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	var target_velocity := Vector3.ZERO
	if direction:
		target_velocity = direction
		# Generate noise while moving
		var move_noise = 0.05 # Base walk noise
		if is_running:
			move_noise = 0.4 # Running noise is high
		elif is_crouching:
			move_noise = 0.01 # Crouching is very silent
		
		GameManager.add_noise(move_noise * (velocity.length() / speed) * delta * 5)
	
	#now apply velocity with lerp based on whether on ground or in air
	if is_on_floor():
		velocity.x = move_toward(velocity.x , target_velocity.x * speed , speed * ground_acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z * speed, speed * ground_acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x , target_velocity.x * speed , speed * air_acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z * speed, speed * air_acceleration * delta)
	#now actually move based on velocity
	move_and_slide()
	
	#rotate the player and camera pivot based on smooth mouse movement
	smooth_mouse_motion = smooth_mouse_motion.lerp(mouse_motion, mouse_smoothing * delta)
	rotate_y(-smooth_mouse_motion.x * mouse_sensitivity / 1000)
	pitch -= smooth_mouse_motion.y * mouse_sensitivity / 1000
	pitch = clampf(pitch,-1.35,1.35)
	camera_pivot.rotation.x = pitch
	#reset mouse motion but keep smooth motion for next frame
	mouse_motion = Vector2.ZERO
	

#handle and store mouse motion
func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		mouse_motion = event.relative

func handle_parkour(_delta):
	if is_on_floor():
		is_climbing = false
		return

	# If we are in the air and moving forward, check for ledges
	if Input.is_action_pressed("forward") and not is_on_floor():
		if chest_ray.is_colliding() and not head_ray.is_colliding():
			# Ledge detected! Chest hits but head is clear
			perform_vault()

func perform_vault():
	if is_climbing: return
	is_climbing = true
	
	# Small noise for climbing
	GameManager.add_noise(0.15)
	
	var tween = create_tween()
	# Move up
	tween.tween_property(self, "global_position", global_position + Vector3(0, 1.5, 0), 0.2)
	# Then move forward a bit
	var forward_dir = -transform.basis.z
	tween.tween_property(self, "global_position", global_position + forward_dir * 1.5 + Vector3(0, 0.5, 0), 0.2)
	
	await tween.finished
	is_climbing = false
	velocity = Vector3.ZERO
