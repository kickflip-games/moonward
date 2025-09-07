extends Area2D

@onready var _flag: = $Flag
@onready var _marker:Marker2D = $FlagMarker
@onready var _sfx:AudioStreamPlayer2D = $sfx
@onready var _fx:CPUParticles2D = $fx

var activated = false

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not activated:
		activated = true
		print("player entered checkpoint")
		body.update_respawn_position(global_position)
		activate_flag()

func activate_flag():
	_sfx.play()
	_fx.emitting = true
	var tween = create_tween()
	tween.tween_property(_flag, "position", _marker.position, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_flag, "modulate", Color.GREEN, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
