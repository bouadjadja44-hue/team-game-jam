extends Area3D

func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		GameManager.reach_safe_zone()
