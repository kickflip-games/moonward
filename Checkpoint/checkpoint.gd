# Checkpoint.gd
extends Area2D
class_name Checkpoint

@onready var _flag: = $Flag

@onready var _marker:Marker2D = $FlagMarker
@onready var _sfx:AudioStreamPlayer2D = $sfx
@onready var _fx:CPUParticles2D = $fx
@onready var _fire_fx:CPUParticles2D = $FIRE
@export var side: float = 100.0

var activated = false


func _ready():
	CheckpointManager.register_checkpoint(self)

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not activated:
		activated = true
		print("player entered checkpoint")
		body.update_respawn_position(global_position)
		CheckpointManager.checkpoint_activated(self)
		activate_flag()

func activate_flag():
	
	_fire_fx.emitting = true
	$Flag.color.a = 1

	
	_sfx.play()
	_fx.emitting = true
	#var tween = create_tween()
	
	#tween.tween_property(_flag, "position", _marker.position, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	#tween.tween_property(_flag, "modulate", Color(2.265, 0.773, 0.342), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
