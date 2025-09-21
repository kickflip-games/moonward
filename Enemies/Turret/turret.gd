@tool
extends Node2D

@export var projectile_scene: PackedScene
@export var shoot_cooldown: float = 1.0
@export var range: float = 300.0 : set = set_range
@export var rotation_speed: float = 3.0
@export var show_debug_range: bool = true : set = set_show_debug_range
@export var projectile_speed: float = 600
@export var projectile_homing: bool = true
@export var projectile_homing_strength: float = 0.01

@onready var _sprite: Node2D = $Sprite

var player: Node2D
var can_shoot: bool = true
var target_rotation: float = 0.0

func set_range(value: float):
	range = value
	queue_redraw()

func set_show_debug_range(value: bool):
	show_debug_range = value
	queue_redraw()

func _ready():
	if Engine.is_editor_hint():
		return # Don’t run gameplay logic in editor

	# Look for player by group
	var players_in_scene = get_tree().get_nodes_in_group("Player")
	if not players_in_scene.is_empty():
		player = players_in_scene[0]
	else:
		print("Player not found!")
		set_process(false)

func _process(delta):
	if Engine.is_editor_hint():
		return # Don’t run gameplay logic in editor

	if player:
		var distance_to_player = global_position.distance_to(player.global_position)
		
		if distance_to_player < range:
			# Aim at player smoothly
			target_rotation = global_position.angle_to_point(player.global_position)
			global_rotation = lerp_angle(global_rotation, target_rotation, rotation_speed * delta)
			
			if can_shoot and has_line_of_sight():
				shoot()

func has_line_of_sight() -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	return result.is_empty() or result.collider == player

func shoot():
	var projectile_instance: Projectile = projectile_scene.instantiate()
	projectile_instance.reset(projectile_homing, projectile_homing_strength, projectile_speed, player)
	projectile_instance.global_position = global_position
	projectile_instance.global_rotation = global_rotation
	get_parent().add_child(projectile_instance)

	can_shoot = false
	var timer = get_tree().create_timer(shoot_cooldown)
	timer.timeout.connect(func(): can_shoot = true)

func _draw():
	if not show_debug_range:
		return

	if Engine.is_editor_hint():
		# Only show range circle in the editor
		draw_arc(Vector2.ZERO, range, 0, TAU, 64, Color.RED, 2.0)
