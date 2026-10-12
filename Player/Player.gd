class_name Player
extends CharacterBody2D

@export_group("Run")
@export var max_speed: float = 560.0
@export var acceleration: float = 4032.0
@export var turning_acceleration: float = 13440.0
@export var deceleration: float = 4480.0
@export var accel_in_air: float = 0.65
@export var deccel_in_air: float = 0.35
@export var air_turning_acceleration: float = 5600.0
@export var do_conserve_momentum: bool = true

@export_group("Jump")
@export var jump_force: float = 1200.0
@export var jump_coyote: float = 0.12
@export var jump_buffer: float = 0.12
## Fraction of upward speed removed on release.
@export_range(0.0, 1.0) var jump_cut: float = 0.45
@export var jump_hang_threshold: float = 120.0
@export var jump_hang_gravity_mult: float = 0.5
@export var jump_hang_accel_mult: float = 1.2
@export var jump_hang_maxspeed_mult: float = 1.0

@export_group("Gravity")
@export var gravity_acceleration: float = 3840.0
@export var gravity_max: float = 1020.0
@export var fall_gravity_mult: float = 1.2
@export var jump_cut_gravity_mult: float = 2.0
@export var fastfall_gravity_mult: float = 3.0

@export_group("Walls")
@export var wall_jump_force: Vector2 = Vector2(620, 1100)
@export var wall_coyote: float = 0.10
## Guaranteed separation, then a smooth return of steering.
@export var wall_jump_time: float = 0.12
@export var wall_jump_steer_time: float = 0.10
## Short taps still produce a useful wall bounce before variable-height cutting.
@export var wall_jump_min_hold: float = 0.12
@export_range(0.0, 1.0) var wall_jump_cut: float = 0.15
@export var slide_speed: float = 100.0

@export_group("Retry")
@export var death_delay: float = 0.35
@export var respawn_grace: float = 0.15
@export var show_debug_state: bool = false

signal died
signal respawned
signal jumped(from_wall: bool)

var face_direction := 1
var x_dir := 0
var is_jumping := false
var is_wall_jumping := false
var is_sliding := false
var _is_jump_cut := false
var _is_jump_falling := false
var _input_locked := false
var is_dead := false
var last_on_ground_time := 0.0
var last_pressed_jump_time := 0.0
var last_on_wall_time := 0.0
var _wall_contact_side := 0 # -1 left, +1 right
var _recent_wall_side := 0
var _wall_jump_timer := 0.0
var _last_wall_jump_dir := 0
var _wall_jump_hold_timer := 0.0
var _wall_jump_cut_pending := false
var _jump_from_wall := false
var _death_timer := 0.0
var _grace_timer := 0.0
var _refresh_contacts := 0
var _respawn_pos := Vector2.ZERO
var _spring_launch := false
var _cached_input := {"x": 0, "y": 0, "just_jump": false,
	"jump": false, "released_jump": false}

@onready var ray_wall_left: RayCast2D = $WallRayLeft
@onready var ray_wall_right: RayCast2D = $WallRayRight
@onready var debug_label: Label = Label.new()

func _ready() -> void:
	_respawn_pos = global_position
	add_child(debug_label)
	debug_label.position = Vector2(-55, -65)
	debug_label.add_theme_font_size_override("font_size", 14)
	debug_label.modulate = Color.YELLOW
	debug_label.visible = show_debug_state
	respawn()

func _physics_process(delta: float) -> void:
	if is_dead:
		_death_timer -= delta
		if _death_timer <= 0.0:
			respawn()
		return
	_grace_timer = maxf(0.0, _grace_timer - delta)
	_update_input_cache()
	last_on_ground_time = maxf(0.0, last_on_ground_time - delta)
	last_on_wall_time = maxf(0.0, last_on_wall_time - delta)
	last_pressed_jump_time = maxf(0.0, last_pressed_jump_time - delta)
	_wall_jump_timer = maxf(0.0, _wall_jump_timer - delta)
	_wall_jump_hold_timer = maxf(0.0, _wall_jump_hold_timer - delta)
	is_wall_jumping = _wall_jump_timer > 0.0
	x_dir = _cached_input.x
	if x_dir != 0:
		set_direction(x_dir)
	_collision_checks()
	if _cached_input.just_jump:
		last_pressed_jump_time = jump_buffer
	_handle_jumps()
	if _cached_input.released_jump and velocity.y < 0.0 and not _spring_launch:
		if _jump_from_wall and _wall_jump_hold_timer > 0.0:
			_wall_jump_cut_pending = true
		else:
			_cut_jump(wall_jump_cut if _jump_from_wall else jump_cut)
	if _wall_jump_cut_pending and _wall_jump_hold_timer <= 0.0:
		_wall_jump_cut_pending = false
		if velocity.y < 0.0:
			_cut_jump(wall_jump_cut)
	x_movement(delta)
	is_sliding = _wall_contact_side != 0 and not is_on_floor() and velocity.y >= 0.0 \
		and not is_wall_jumping and x_dir != -_wall_contact_side
	_apply_gravity_and_limits(delta)
	# Forget the engine's old platform contact for the first moves after teleport.
	platform_floor_layers = 0 if _refresh_contacts > 0 else 2
	platform_wall_layers = 0 if _refresh_contacts > 0 else 2
	platform_on_leave = PLATFORM_ON_LEAVE_DO_NOTHING if _refresh_contacts > 0 \
		else PLATFORM_ON_LEAVE_ADD_UPWARD_VELOCITY
	move_and_slide()
	_refresh_contacts = maxi(0, _refresh_contacts - 1)
	if is_on_ceiling():
		velocity.y = maxf(velocity.y, 0.0)
		_is_jump_cut = false
		_spring_launch = false
	if is_on_floor() and velocity.y >= 0.0:
		_reset_jump_state()
		last_on_ground_time = jump_coyote
		# Inputs buffered immediately before a landing fire on that landing.
		_handle_jumps()
	if show_debug_state:
		debug_label.text = "wall: %d  coyote: %.2f\n%s" % [_wall_contact_side,
			last_on_wall_time, "SLIDE" if is_sliding else "JUMP" if is_jumping else "RUN"]

func _update_input_cache() -> void:
	_cached_input.x = 0 if _input_locked else int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	_cached_input.y = 0 if _input_locked else int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	_cached_input.just_jump = not _input_locked and Input.is_action_just_pressed("jump")
	_cached_input.jump = not _input_locked and Input.is_action_pressed("jump")
	_cached_input.released_jump = not _input_locked and Input.is_action_just_released("jump")

func get_input() -> Dictionary:
	return _cached_input

func _collision_checks() -> void:
	if _refresh_contacts == 0 and is_on_floor() and velocity.y >= 0.0:
		last_on_ground_time = jump_coyote
		_reset_jump_state()
	ray_wall_left.force_raycast_update()
	ray_wall_right.force_raycast_update()
	var left := ray_wall_left.is_colliding() and ray_wall_left.get_collision_normal().x > 0.7
	var right := ray_wall_right.is_colliding() and ray_wall_right.get_collision_normal().x < -0.7
	_wall_contact_side = 0
	if left and right:
		# Physical slide normal wins in tight shafts; input and recency break ties.
		if _refresh_contacts == 0 and is_on_wall():
			_wall_contact_side = -int(signf(get_wall_normal().x))
		if _wall_contact_side == 0:
			_wall_contact_side = x_dir if x_dir != 0 else _recent_wall_side if _recent_wall_side != 0 else -face_direction
	elif left:
		_wall_contact_side = -1
	elif right:
		_wall_contact_side = 1
	if _wall_contact_side != 0 and not is_on_floor():
		_recent_wall_side = _wall_contact_side
		last_on_wall_time = wall_coyote

func x_movement(delta: float) -> void:
	var control := 1.0
	if _wall_jump_timer > wall_jump_steer_time:
		return
	if _wall_jump_timer > 0.0:
		control = 1.0 - _wall_jump_timer / maxf(wall_jump_steer_time, 0.001)
	var grounded := is_on_floor() and velocity.y >= 0.0 and _refresh_contacts == 0
	var target := float(x_dir) * max_speed
	var rate := acceleration if grounded else acceleration * accel_in_air
	if x_dir == 0:
		rate = deceleration if grounded else deceleration * deccel_in_air
	elif velocity.x * x_dir < 0.0:
		rate = turning_acceleration if grounded else air_turning_acceleration
	elif not grounded and do_conserve_momentum and absf(velocity.x) > absf(target):
		# External launches retain speed until the player brakes or turns.
		return
	if is_jumping and not _is_jump_cut and absf(velocity.y) < jump_hang_threshold:
		rate *= jump_hang_accel_mult
		target *= jump_hang_maxspeed_mult
	velocity.x = move_toward(velocity.x, target, rate * control * delta)

func set_direction(direction: int) -> void:
	if direction != 0:
		face_direction = direction

func _handle_jumps() -> void:
	if last_pressed_jump_time <= 0.0 or _input_locked:
		return
	if last_on_ground_time > 0.0 and not is_jumping:
		_perform_jump()
		return
	var side := _wall_contact_side if _wall_contact_side != 0 else _recent_wall_side
	if last_on_wall_time > 0.0 and side != 0:
		# A fresh opposite wall can interrupt protection for quick shaft jumps.
		if not is_wall_jumping or side == _last_wall_jump_dir:
			_perform_wall_jump(side)

func _cut_jump(amount: float) -> void:
	_is_jump_cut = true
	velocity.y *= 1.0 - amount

func _consume_jump() -> void:
	_wall_jump_hold_timer = 0.0
	_wall_jump_cut_pending = false
	_jump_from_wall = false
	last_pressed_jump_time = 0.0
	last_on_ground_time = 0.0
	last_on_wall_time = 0.0
	_recent_wall_side = 0
	_is_jump_cut = false
	_is_jump_falling = false
	is_sliding = false
	is_jumping = true
	_spring_launch = false

func _perform_jump() -> void:
	_consume_jump()
	velocity.y = -jump_force
	if not _cached_input.jump:
		velocity.y *= 1.0 - jump_cut
		_is_jump_cut = true
	jumped.emit(false)

func _perform_wall_jump(side: int = 0) -> void:
	if side == 0:
		side = _wall_contact_side if _wall_contact_side != 0 else _recent_wall_side
	if side == 0:
		return
	_consume_jump()
	_last_wall_jump_dir = -side
	is_wall_jumping = true
	_wall_jump_timer = wall_jump_time + wall_jump_steer_time
	velocity = Vector2(wall_jump_force.x * -side, -wall_jump_force.y)
	_jump_from_wall = true
	_wall_jump_hold_timer = wall_jump_min_hold
	_wall_jump_cut_pending = not _cached_input.jump
	set_direction(-side)
	jumped.emit(true)

func _apply_gravity_and_limits(delta: float) -> void:
	if is_on_floor() and velocity.y >= 0.0:
		return
	var gravity := gravity_acceleration
	if _is_jump_cut and velocity.y < 0.0:
		gravity *= jump_cut_gravity_mult
	elif is_jumping and absf(velocity.y) < jump_hang_threshold:
		gravity *= jump_hang_gravity_mult
	elif velocity.y > 0.0:
		gravity *= fall_gravity_mult
	if _cached_input.y > 0:
		gravity *= fastfall_gravity_mult
	velocity.y = minf(velocity.y + gravity * delta, gravity_max)
	if is_sliding:
		velocity.y = minf(velocity.y, slide_speed)
	if velocity.y >= 0.0:
		is_jumping = false
		_is_jump_falling = true
		_spring_launch = false

func _reset_jump_state() -> void:
	_wall_jump_hold_timer = 0.0
	_wall_jump_cut_pending = false
	_jump_from_wall = false
	is_jumping = false
	is_wall_jumping = false
	is_sliding = false
	_is_jump_cut = false
	_is_jump_falling = false
	_wall_jump_timer = 0.0
	_spring_launch = false

func launch(launch_velocity: Vector2) -> void:
	if is_dead:
		return
	_consume_jump()
	is_wall_jumping = false
	_wall_jump_timer = 0.0
	_spring_launch = true
	velocity = launch_velocity
	jumped.emit(false)

func should_play_somersault() -> bool:
	return is_jumping and not is_sliding and not is_wall_jumping and absf(velocity.y) > 100.0

func update_respawn_position(pos: Vector2) -> void:
	_respawn_pos = pos

func die() -> void:
	if is_dead or _grace_timer > 0.0:
		return
	is_dead = true
	_input_locked = true
	velocity = Vector2.ZERO
	_death_timer = death_delay
	died.emit()

func respawn() -> void:
	global_position = _respawn_pos
	velocity = Vector2.ZERO
	_reset_jump_state()
	last_on_ground_time = 0.0
	last_on_wall_time = 0.0
	last_pressed_jump_time = 0.0
	_wall_contact_side = 0
	_recent_wall_side = 0
	_last_wall_jump_dir = 0
	_death_timer = 0.0
	_grace_timer = respawn_grace
	_refresh_contacts = 2
	is_dead = false
	_input_locked = false
	x_dir = 0
	face_direction = 1
	for key in _cached_input:
		_cached_input[key] = false if key in ["just_jump", "jump", "released_jump"] else 0
	reset_physics_interpolation()
	respawned.emit()

func _on_hurt_area_body_entered(_body: Node2D) -> void:
	die()

func _on_hurt_area_entered(_area: Area2D) -> void:
	die()
