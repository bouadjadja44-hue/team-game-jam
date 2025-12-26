extends Node3D

@export_group("Footstep Audio Settings")
@export var footstep_sound : AudioStream
@export var step_interval : float = 0.5  # Time between footsteps
@export var volume_db : float = -10.0  # Volume of footsteps

var audio_player : AudioStreamPlayer3D
var step_timer : float = 0.0
var is_moving : bool = false
var was_moving : bool = false

func _ready():
	# Create audio player
	audio_player = AudioStreamPlayer3D.new()
	add_child(audio_player)
	audio_player.stream = footstep_sound
	audio_player.volume_db = volume_db

func _process(delta):
	var player = get_parent().get_parent()
	
	# Check if player is moving
	var current_is_moving = false
	if player.has_method("is_on_floor"):
		var is_on_ground = player.is_on_floor()
		var velocity = player.velocity if "velocity" in player else Vector3.ZERO
		var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
		current_is_moving = horizontal_velocity.length() > 0.1 and is_on_ground
	
	# Stop audio immediately when player stops moving
	if not current_is_moving and audio_player.playing:
		audio_player.stop()
		step_timer = 0.0
	
	# Play footsteps when moving
	if current_is_moving:
		step_timer += delta
		if step_timer >= step_interval:
			play_footstep()
			step_timer = 0.0
	
	is_moving = current_is_moving

func play_footstep():
	if audio_player and audio_player.stream:
		audio_player.play()
