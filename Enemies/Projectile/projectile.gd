extends CharacterBody2D

@export var speed: float = 500.0
@export var is_homing: bool = false
@export var homing_strength: float = 0.01

var target: Node2D

func _physics_process(delta):
	var direction = Vector2.RIGHT.rotated(rotation)

	if is_homing and target:
		var target_direction = global_position.direction_to(target.global_position)
		direction = lerp(direction, target_direction, homing_strength)
		
	velocity = direction * speed
	move_and_slide()

func set_target(new_target: Node2D):
	target = new_target

func _on_body_entered(body):
	queue_free() # Destroy the projectile
