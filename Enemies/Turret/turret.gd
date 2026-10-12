@tool
extends Node2D

@export var projectile_scene: PackedScene
@export var shoot_cooldown: float = 1.0
@export var range: float = 300.0 : set = set_range
@export var rotation_speed: float = 3.0
@export var show_debug_range: bool = true : set = set_show_debug_range
@export var projectile_speed: float = 600.0
@export var projectile_homing: bool = true
@export var projectile_homing_strength: float = 0.01
@export var warning_time: float = 0.5
@export var require_on_screen: bool = true
@export var warning_color: Color = Color(1, 0.36, 0.24)

signal charging
signal fired

@onready var _sprite: Node2D = $Sprite
@onready var _warning_sfx: AudioStreamPlayer2D = $WarningSFX
var player: Player
var can_shoot := true
var charge_remaining := 0.0
var cooldown_remaining := 0.0
var is_charging := false

func set_range(value: float) -> void:
	range = value
	queue_redraw()

func set_show_debug_range(value: bool) -> void:
	show_debug_range = value
	queue_redraw()

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var players = get_tree().get_nodes_in_group("Player")
	if not players.is_empty():
		player = players[0] as Player

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	can_shoot = cooldown_remaining <= 0.0
	if not is_instance_valid(player) or player.is_dead or player._grace_timer > 0.0:
		cancel_charge()
		return
	if require_on_screen and not get_viewport_rect().grow(-64.0).has_point(get_global_transform_with_canvas().origin):
		cancel_charge()
		return
	var in_range := global_position.distance_to(player.global_position) < range
	if not in_range or not has_line_of_sight():
		cancel_charge()
		return
	var target_rotation := global_position.angle_to_point(player.global_position)
	global_rotation = lerp_angle(global_rotation, target_rotation, 1.0 - exp(-rotation_speed * delta))
	if can_shoot and not is_charging:
		is_charging = true
		charge_remaining = warning_time
		_warning_sfx.play()
		charging.emit()
	if is_charging:
		charge_remaining -= delta
		var progress := 1.0 - charge_remaining / maxf(warning_time, 0.001)
		_sprite.modulate = Color.WHITE.lerp(warning_color, 0.3 + 0.7 * progress)
		queue_redraw()
		if charge_remaining <= 0.0:
			shoot()

func has_line_of_sight() -> bool:
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position, 3)
	query.exclude = [player.get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func cancel_charge() -> void:
	is_charging = false
	charge_remaining = 0.0
	if is_instance_valid(_sprite):
		_sprite.modulate = Color.WHITE
	if is_instance_valid(_warning_sfx):
		_warning_sfx.stop()
	queue_redraw()

func shoot() -> void:
	if not projectile_scene or not is_instance_valid(player):
		cancel_charge()
		return
	var projectile: Projectile = projectile_scene.instantiate()
	projectile.reset(projectile_homing, projectile_homing_strength, projectile_speed, player)
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2.RIGHT.rotated(global_rotation) * 52.0
	projectile.global_rotation = global_rotation
	cooldown_remaining = shoot_cooldown
	can_shoot = false
	cancel_charge()
	fired.emit()

func _draw() -> void:
	if Engine.is_editor_hint() and show_debug_range:
		draw_arc(Vector2.ZERO, range, 0, TAU, 64, Color.RED, 2.0)
	elif is_charging:
		# A growing ring reads even when the barrel points away from the viewer.
		var progress := 1.0 - charge_remaining / maxf(warning_time, 0.001)
		draw_arc(Vector2.ZERO, 55.0 + progress * 12.0, 0, TAU, 32, warning_color, 3.0)
