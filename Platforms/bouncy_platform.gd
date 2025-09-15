extends StaticBody2D

@export var bounce_force: float = 500.0
@export var bounce_direction: Vector2 = Vector2(0, -1)  # Can bounce at angles!
@export var min_bounce_velocity: float = 100.0  # Minimum downward speed to trigger bounce
@export var bounce_animation_scale: float = 1.2

@onready var sprite = $Sprite2D
@onready var area = $Area2D

func _ready():
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		# Check if player is moving downward fast enough (landing on platform)
		if body.velocity.y > min_bounce_velocity:
			bounce_player(body)

func bounce_player(player):
	# Calculate bounce velocity based on direction and force
	var bounce_velocity = bounce_direction.normalized() * bounce_force
	
	# For CharacterBody2D, directly set the velocity
	player.velocity.x = bounce_velocity.x  # Keep or change horizontal momentum
	player.velocity.y = bounce_velocity.y  # Set vertical bounce
	
	animate_platform_bounce()

func animate_platform_bounce():
	var tween = create_tween()
	tween.set_parallel(true)  # Allow multiple animations at once
	
	# Squish and bounce back
	tween.tween_property(sprite, "scale:y", 0.7, 0.08)
	tween.tween_property(sprite, "scale:x", 1.1, 0.08)
	
	tween.tween_property(sprite, "scale:y", bounce_animation_scale, 0.12)
	tween.tween_property(sprite, "scale:x", 0.95, 0.12)
	
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15)



