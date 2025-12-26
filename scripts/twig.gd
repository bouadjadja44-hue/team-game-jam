extends Area3D

@export var noise_amount: float = 0.2 # 15-25% as requested

func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		GameManager.add_noise(noise_amount)
		# Optional: Play a "crack" sound
		# $AudioStreamPlayer3D.play()
		print("Stepped on a twig!")
