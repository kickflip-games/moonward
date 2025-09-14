extends CharacterBody2D

@export var speed: float = 500.0
@export var is_homing: bool = false
@export var homing_strength: float = 0.01
@onready var shatter_particles: CPUParticles2D = $ShatterParticles
@onready var sprite = $Triangle


var target: Node2D

func _physics_process(delta):
	var direction = Vector2.RIGHT.rotated(rotation)
	if is_homing and target:
		var target_direction = global_position.direction_to(target.global_position)
		direction = direction.lerp(target_direction, homing_strength)
		rotation = direction.angle()
		
	velocity = direction * speed

	var collision = move_and_collide(velocity * delta)
	if collision:
		handle_collision(collision.get_collider())

func set_target(new_target: Node2D):
	target = new_target

func handle_collision(body):
	if body is Player:
		body.die()
	shatter_on_ground()

func shatter_on_ground():
	sprite.hide()
	$CollisionShape2D.disabled = true
	$Hurtzone.queue_free()
	shatter_particles.emitting = true
	await shatter_particles.finished
	queue_free()
