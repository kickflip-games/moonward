extends Node

## Adds bounded anticipation to the existing PhantomCamera follow system.
@export var upward_bias: float = 70.0
@export var vertical_lookahead: float = 150.0
@export var horizontal_lookahead: float = 55.0
@export var lookahead_response: float = 6.0
@export var vertical_velocity_scale: float = 0.085
@export var horizontal_velocity_scale: float = 0.075
@export var framing_response: float = 3.0

@onready var phantom: PhantomCamera2D = get_parent()
var player: Player
var offset := Vector2.ZERO
var zones: Array[Node] = []

func _ready() -> void:
	player = phantom.follow_target as Player
	if not player:
		set_physics_process(false)
		return
	player.respawned.connect(_on_respawned)
	zones = get_tree().get_nodes_in_group("camera_framing_zones")
	_on_respawned()

func _physics_process(delta: float) -> void:
	var target := Vector2(
		clampf(player.velocity.x * horizontal_velocity_scale, -horizontal_lookahead, horizontal_lookahead),
		-upward_bias + clampf(player.velocity.y * vertical_velocity_scale, -vertical_lookahead, 35.0))
	# Suppress rapid horizontal oscillations in alternating wall jumps.
	if player.is_wall_jumping or player.is_sliding:
		target.x *= 0.35
	offset = offset.lerp(target, 1.0 - exp(-lookahead_response * delta))
	phantom.follow_offset = offset
	phantom.zoom = phantom.zoom.lerp(_target_zoom(), 1.0 - exp(-framing_response * delta))

func _target_zoom() -> Vector2:
	var zoom := 1.0
	for zone in zones:
		if is_instance_valid(zone) and zone.contains(player.global_position):
			zoom = minf(zoom, zone.zoom)
	return Vector2.ONE * zoom

func _on_respawned() -> void:
	offset = Vector2(0, -upward_bias)
	phantom.follow_offset = offset
	phantom.zoom = _target_zoom()
	phantom.teleport_position.call_deferred()
