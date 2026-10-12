# Checkpoint.gd
extends Area2D
class_name Checkpoint

@onready var _flag: = $Flag

@onready var _marker:Marker2D = $FlagMarker
@onready var _sfx:AudioStreamPlayer2D = $sfx
@onready var _fx:CPUParticles2D = $fx
@onready var _fire_fx:CPUParticles2D = $FIRE
@export var side: float = 100.0
## -1 uses bottom-to-top height ordering for practice/custom scenes.
@export var progression_index: int = -1

var activated = false


func _ready():
	CheckpointManager.register_checkpoint(self)

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not body.is_dead:
		activate_for(body)

func activate_for(body: Player) -> void:
	if not activated and CheckpointManager.player == body and CheckpointManager.checkpoint_activated(self):
		activated = true
		activate_flag()

func activate_flag():
	
	_fire_fx.emitting = true
	$Flag.color.a = 1

	
	_sfx.play()
	_fx.emitting = true
	#var tween = create_tween()
	
	#tween.tween_property(_flag, "position", _marker.position, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	#tween.tween_property(_flag, "modulate", Color(2.265, 0.773, 0.342), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
