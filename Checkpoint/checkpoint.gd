extends Area2D

@onready var _sprite = $Sprite2D


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		print("player entered checkpoint")
		_sprite.self_modulate = Color.GREEN
		body.update_respawn_position(global_position)
