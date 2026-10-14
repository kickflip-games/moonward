@tool
extends Node2D

@export var room_id := 1
@export var room_name := "Switchback Ascent"
@export var floor_y := 0.0
@export var rise := 768.0
var player: Player
var active := true

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not is_instance_valid(player):
		player = CheckpointManager.player
		if not is_instance_valid(player):
			return
		player.respawned.connect(_retry)
	var nearby := absf(player.global_position.y - (global_position.y - rise / 2)) < rise / 2 + 900
	if nearby != active:
		active = nearby
		$Mechanisms.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED

func _retry() -> void:
	if absf(player.global_position.y - global_position.y) < rise + 100:
		for trap in $Mechanisms.get_children():
			if trap.has_method("reset_cycle"):
				trap.reset_cycle()
