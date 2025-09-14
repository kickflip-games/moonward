@tool
extends Node2D

@export var projectile_scene: PackedScene
@export var shoot_cooldown: float = 1.0
@export var range: float = 300.0 : set = set_range
@export var rotation_speed: float = 3.0
@export var show_debug_range: bool = true : set = set_show_debug_range
@onready var _sprite: Node2D = $Sprite

var player: Node2D
var can_shoot: bool = true
var target_rotation: float = 0.0

func set_range(value: float):
	range = value
	queue_redraw() # Update visuals when range changes

func set_show_debug_range(value: bool):
	show_debug_range = value
	queue_redraw() # Update visuals when debug toggle changes

func _ready():
	if Engine.is_editor_hint():
		return # Don't run game logic in editor
	
	# Find the player node. A common way is to use a group.
	# Ensure your player node is in a group named "player".
	var players_in_scene = get_tree().get_nodes_in_group("Player")
	if not players_in_scene.is_empty():
		player = players_in_scene[0]
	else:
		print("Player not found!")
		set_process(false) # Disable script if player isn't found

func _process(delta):
	if Engine.is_editor_hint():
		return # Don't run game logic in editor
		
	if player:
		var distance_to_player = global_position.distance_to(player.global_position)
		
		if distance_to_player < range:
			# Aim at player smoothly
			target_rotation = global_position.angle_to_point(player.global_position)
			global_rotation = lerp_angle(global_rotation, target_rotation, rotation_speed * delta)
			
			# Check line of sight and shoot if we can
			if can_shoot and has_line_of_sight():
				shoot()

func has_line_of_sight() -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	query.exclude = [self] # Don't hit the turret itself
	var result = space_state.intersect_ray(query)
	return result.is_empty() or result.collider == player

func shoot():
	# Create a new projectile instance
	var projectile_instance = projectile_scene.instantiate()
	
	# Place the projectile at the turret's position and set its rotation
	projectile_instance.global_position = global_position
	projectile_instance.global_rotation = global_rotation
	
	# Pass the player's position to the projectile for homing, if applicable
	if projectile_instance.has_method("set_target"):
		projectile_instance.set_target(player)
	
	# Add the projectile to the scene tree
	get_parent().add_child(projectile_instance)
	
	# Start cooldown
	can_shoot = false
	var timer = get_tree().create_timer(shoot_cooldown)
	timer.timeout.connect(func(): can_shoot = true)

func _draw():
	if not show_debug_range:
		return
		
	# Always draw range circle (both in editor and game)
	draw_arc(Vector2.ZERO, range, 0, TAU, 64, Color.RED, 2.0)
	
	# Only draw line of sight in game, not in editor
	if not Engine.is_editor_hint() and player:
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player < range:
			var local_player_pos = to_local(player.global_position)
			var color = Color.GREEN if has_line_of_sight() else Color.RED
			draw_line(Vector2.ZERO, local_player_pos, color, 2.0)

# Call this in _process to update the debug visuals during gameplay
func _notification(what):
	if what == NOTIFICATION_PROCESS and not Engine.is_editor_hint():
		queue_redraw() # This ensures _draw() is called every frame during gameplay
