extends Node2D

@export var projectile_scene: PackedScene
@export var shoot_cooldown: float = 1.0
@export var range: float = 300.0

@onready var _sprite: Node2D = $Sprite

var player: Node2D
var can_shoot: bool = true

func _ready():
	# Find the player node. A common way is to use a group.
	# Ensure your player node is in a group named "player".
	var players_in_scene = get_tree().get_nodes_in_group("player")
	if not players_in_scene.is_empty():
		player = players_in_scene[0]
	else:
		print("Player not found!")
		set_process(false) # Disable script if player isn't found

func _process(delta):
	if player and can_shoot:
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player < range:
			aim_and_shoot()

func aim_and_shoot():
	# Aim at the player
	look_at(player.global_position)
	
	# Create a new projectile instance
	var projectile_instance = projectile_scene.instantiate()
	
	# Place the projectile at the turret's position
	projectile_instance.global_position = global_position
	
	# Pass the player's position to the projectile for homing, if applicable
	if projectile_instance.has_method("set_target"):
		projectile_instance.set_target(player)
	
	# Add the projectile to the scene tree
	get_parent().add_child(projectile_instance)
	
	# Start cooldown
	can_shoot = false
	var timer = get_tree().create_timer(shoot_cooldown)
	timer.timeout.connect(func(): can_shoot = true)
