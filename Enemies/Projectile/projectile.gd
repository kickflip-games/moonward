class_name Projectile
extends CharacterBody2D

@export var _speed: float = 500.0
@export var _is_homing: bool = false
@export var _homing_strength: float = 0.01
@export var max_turn_speed: float = 1.2
@export var homing_duration: float = 0.6
@export var lifetime: float = 4.0
@onready var shatter_particles: CPUParticles2D = $ShatterParticles
@onready var sprite: Node2D = $Triangle
const SURFACE = preload("res://Art/Dungeon/surface_material.gd")

var target: Node2D
var age := 0.0
var shattered := false

func _ready() -> void:
	SURFACE.skin(sprite, SURFACE.SPIKE, true)

func reset(homing: bool, strength: float, speed: float, new_target: Node2D) -> void:
	_homing_strength = strength
	_speed = speed
	_is_homing = homing
	target = new_target

func _physics_process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		shatter_on_ground()
		return
	if _is_homing and age <= homing_duration and is_instance_valid(target) and not target.is_dead:
		var target_angle := global_position.angle_to_point(target.global_position)
		# Legacy strength was per frame. Convert once to a bounded radians/second rate.
		var turn_rate := minf(_homing_strength * 60.0, max_turn_speed)
		global_rotation = rotate_toward(global_rotation, target_angle, turn_rate * delta)
	velocity = Vector2.RIGHT.rotated(global_rotation) * _speed
	var collision = move_and_collide(velocity * delta)
	if collision:
		handle_collision(collision.get_collider())

func handle_collision(body: Node) -> void:
	if shattered:
		return
	if body is Player:
		body.die()
	shatter_on_ground()

func shatter_on_ground() -> void:
	if shattered:
		return
	shattered = true
	set_physics_process(false)
	sprite.hide()
	$CollisionShape2D.set_deferred("disabled", true)
	$Hurtzone.set_deferred("monitoring", false)
	shatter_particles.restart()
	await get_tree().create_timer(0.7).timeout
	queue_free()
