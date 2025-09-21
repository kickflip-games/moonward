class_name Projectile
extends CharacterBody2D

@export var _speed: float = 500.0
@export var _is_homing: bool = false
@export var _homing_strength: float = 0.01
@onready var shatter_particles: CPUParticles2D = $ShatterParticles
@onready var sprite = $Triangle


var target: Node2D

func reset(homing:bool, homing_strength:float, speed:float, new_target:Node2D):
	_homing_strength = homing_strength
	_speed = speed
	_is_homing = homing
	target = new_target

func _physics_process(delta):
	var direction = Vector2.RIGHT.rotated(rotation)
	if _is_homing and target:
		var target_direction = global_position.direction_to(target.global_position)
		direction = direction.lerp(target_direction, _homing_strength)
		rotation = direction.angle()
		
	velocity = direction * _speed

	var collision = move_and_collide(velocity * delta)
	if collision:
		handle_collision(collision.get_collider())


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
