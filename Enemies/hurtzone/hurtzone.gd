class_name Hurtzone
extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		# Assume the Player has a `die()` function that handles death/respawn
		if body.has_method("die"):
			body.die()
