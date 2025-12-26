extends CanvasLayer

var noise_bar: ProgressBar
var alert_bar: ProgressBar
var plant_bar: ProgressBar
var plant_prompt: Label
var objective_label: Label
var status_label: Label

func _ready():
	var control = Control.new()
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(control)
	
	# Status Vertical Box (Top Left)
	var status_vbox = VBoxContainer.new()
	status_vbox.position = Vector2(20, 20)
	control.add_child(status_vbox)
	
	# Noise
	var noise_label = Label.new()
	noise_label.text = "NOISE LEVEL"
	status_vbox.add_child(noise_label)
	noise_bar = ProgressBar.new()
	noise_bar.custom_minimum_size = Vector2(200, 20)
	noise_bar.max_value = 100
	status_vbox.add_child(noise_bar)
	
	# Alert
	var alert_label = Label.new()
	alert_label.text = "ALERT LEVEL"
	status_vbox.add_child(alert_label)
	alert_bar = ProgressBar.new()
	alert_bar.custom_minimum_size = Vector2(200, 20)
	alert_bar.max_value = 100
	status_vbox.add_child(alert_bar)

	# Interaction / Planting Prompt (Center)
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	control.add_child(center_container)

	var interaction_vbox = VBoxContainer.new()
	center_container.add_child(interaction_vbox)

	plant_prompt = Label.new()
	plant_prompt.text = "HOLD (E) TO PLANT BOMB"
	plant_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plant_prompt.hide()
	interaction_vbox.add_child(plant_prompt)

	plant_bar = ProgressBar.new()
	plant_bar.custom_minimum_size = Vector2(300, 30)
	plant_bar.max_value = 100
	plant_bar.hide()
	interaction_vbox.add_child(plant_bar)
	
	# Objective Label (Top Right)
	objective_label = Label.new()
	objective_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	objective_label.position = Vector2(-20, 20)
	objective_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	control.add_child(objective_label)
	
	# Final Game Over Status Label
	status_label = Label.new()
	status_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 48)
	status_label.hide()
	control.add_child(status_label)
	
	GameManager.connect("noise_changed", _on_noise_changed)
	GameManager.connect("alert_level_changed", _on_alert_changed)
	GameManager.connect("planting_progress_changed", _on_planting_changed)
	GameManager.connect("objective_updated", _on_objective_updated)
	GameManager.connect("game_over", _on_game_over)
	objective_label.text = GameManager.current_objective

func _process(_delta):
	# Show prompt if near tank
	var player = get_tree().get_first_node_in_group("player")
	var objective = get_tree().get_first_node_in_group("objective")
	if player and objective and not GameManager.bomb_planted:
		var tank = objective 
		var dist = player.global_position.distance_to(tank.global_position)
		if dist < 5.0: # Increased range for comfort
			plant_prompt.show()
		else:
			plant_prompt.hide()
	else:
		plant_prompt.hide()

func _on_noise_changed(new_level: float):
	noise_bar.value = new_level * 100

func _on_alert_changed(new_level: float):
	alert_bar.value = new_level * 100
	if new_level > 0.7:
		alert_bar.modulate = Color(1, 0, 0)
	else:
		alert_bar.modulate = Color(1, 1, 1)

func _on_planting_changed(progress: float):
	if progress > 0:
		plant_bar.show()
		plant_bar.value = progress * 100
	else:
		plant_bar.hide()

func _on_objective_updated(text: String):
	objective_label.text = text

func _on_game_over(success: bool):
	status_label.show()
	if success:
		status_label.text = "MISSION SUCCESSFUL! LONG LIVE PALESTINE!"
		status_label.modulate = Color(0, 1, 0)
	else:
		status_label.text = "YOU WERE DETECTED! TRY AGAIN"
		status_label.modulate = Color(1, 0, 0)
