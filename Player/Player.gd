class_name Player
extends CharacterBody2D

# ----- Visual / direction ----------
var face_direction := 1
var x_dir := 1

# ----- Run / ground movement (tweak in inspector) -----
@export var max_speed: float = 560
@export var acceleration: float = 2880
@export var turning_acceleration : float = 9600
@export var deceleration: float = 3200

# conserve momentum toggles
@export var do_conserve_momentum: bool = true
@export var accel_in_air: float = 0.6
@export var deccel_in_air: float = 0.6

# jump hang apex multipliers
@export var jump_hang_accel_mult: float = 1.5
@export var jump_hang_maxspeed_mult: float = 1.15

# ----- Gravity -----
@export var gravity_acceleration : float = 3840
@export var gravity_max : float = 1020

# Multipliers for different fall states
@export var fall_gravity_mult: float = 1.2
@export var jump_cut_gravity_mult: float = 2.0
@export var fastfall_gravity_mult: float = 3.0
@export var jump_hang_gravity_mult : float = 0.1

# ----- Jump -----
@export var jump_force : float = 1400
@export var jump_cut : float = 0.25
@export var jump_gravity_max : float = 500
@export var jump_hang_treshold : float = 2.0

# timers
@export var jump_coyote : float = 0.08
@export var jump_buffer : float = 0.1

var jump_coyote_timer : float = 0.0
var jump_buffer_timer : float = 0.0
var is_jumping := false
var _is_jump_cut := false
var _is_jump_falling := false

# fall damag
@export var max_fall_height :float = 500
var _last_grounded_y : float = 0.0
var _is_airborne:bool = false

# ----- Wall interaction (tweak in inspector) -----
@export var wall_check_front_offset := Vector2(12, 0)
@export var wall_check_back_offset := Vector2(-12, 0)
@export var wall_check_size := Vector2(8, 24)
@onready var ground_cast: ShapeCast2D = $GroundCast
@onready var ray_wall_left: RayCast2D = $WallRayLeft
@onready var ray_wall_right: RayCast2D = $WallRayRight

#@export var collision_mask : int = 1 # set this to the layer mask that counts as ground/walls

# wall timers (coyote-style)
var last_on_ground_time : float = 0.0
var last_on_wall_time : float = 0.0
var last_on_wall_left_time : float = 0.0
var last_on_wall_right_time : float = 0.0
var last_pressed_jump_time : float = 0.0

# wall jump params
@export var wall_jump_force := Vector2(520, 1000) # x,y (x applied away from wall)
@export var wall_jump_time : float = 0.12
@export var wall_jump_run_lerp : float = 0.5

var is_wall_jumping := false
var _wall_jump_timer : float = 0.0 # <-- REPLACED engine-time logic with this timer
var _last_wall_jump_dir : int = 0

# slide params
@export var slide_speed : float = 120.0 # positive value; caps downward speed while sliding
@export var slide_accel : float = 600.0

var is_sliding := false
var _input_locked:=true


signal died
signal respawned



# respawn location
var _respawn_pos:Vector2 = Vector2.ZERO


func _ready() -> void:
	_respawn_pos = global_position
	respawn()

# input helper (kept from your version)
func get_input() -> Dictionary:
	if _input_locked:
		return {
			"x": 0,
			"y": 0,
			"just_jump": false,
			"jump": false,
			"released_jump": false
		}
	
	return {
		"x": int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left")),
		"y": int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up")),
		"just_jump": Input.is_action_just_pressed("jump"),
		"jump": Input.is_action_pressed("jump"),
		"released_jump": Input.is_action_just_released("jump")
	}

func _physics_process(delta: float) -> void:
	# Update timers (includes wall jump timer)
	_update_timers(delta)

	# do collision checks (ground + walls) that update the "last_on_*" timers
	_collision_checks()

	# read input and set direction for visuals
	x_dir = get_input()["x"]
	if x_dir != 0:
		set_direction(x_dir)

	# handle jump button buffering (maps to last_pressed_jump_time)
	if get_input()["just_jump"]:
		last_pressed_jump_time = jump_buffer

	# Decide jumps (ground or wall)
	_handle_jumps()

	# movement (run) - pass lerp factor 1 normally, lower during wall-jump for a short while
	var run_lerp = 1.0
	if is_wall_jumping and _wall_jump_timer > 0.0:
		# slightly reduce control immediately after wall jump
		run_lerp = wall_jump_run_lerp
	x_movement(delta, run_lerp)

	# Wall slide detection
	_update_slide_state()

	# gravity & vertical behavior
	_apply_gravity_and_limits(delta)

	# Move
	move_and_slide()

	# expire wall-jump state once timer runs out
	if is_wall_jumping and _wall_jump_timer <= 0.0:
		is_wall_jumping = false
		
	if not is_on_floor():
		# just started falling
		if not _is_airborne:
			_last_grounded_y = position.y
			_is_airborne = true
	else:
		# just landed
		if _is_airborne:
			var fall_height = position.y - _last_grounded_y
			if fall_height > max_fall_height:
				print("Fell to death (height = %s)" % fall_height)
				die()
			_is_airborne = false

func _update_timers(delta: float) -> void:
	jump_coyote_timer = max(jump_coyote_timer - delta, -1.0)
	jump_buffer_timer = max(jump_buffer_timer - delta, -1.0)
	last_on_ground_time = max(last_on_ground_time - delta, -1.0)
	last_on_wall_time = max(last_on_wall_time - delta, -1.0)
	last_on_wall_left_time = max(last_on_wall_left_time - delta, -1.0)
	last_on_wall_right_time = max(last_on_wall_right_time - delta, -1.0)
	last_pressed_jump_time = max(last_pressed_jump_time - delta, -1.0)

	# decrement wall-jump timer (replacement for OS/Engine calls)
	if _wall_jump_timer > 0.0:
		_wall_jump_timer = max(_wall_jump_timer - delta, 0.0)

func _collision_checks() -> void:
	# Ground using ShapeCast2D
	if ground_cast.is_colliding():
		last_on_ground_time = jump_coyote
		jump_coyote_timer = jump_coyote
		is_jumping = false
		_is_jump_falling = false
	# Wall checks (RayCast2D)
	if ray_wall_right.is_colliding():
		last_on_wall_right_time = jump_coyote
	if ray_wall_left.is_colliding():
		last_on_wall_left_time = jump_coyote
	last_on_wall_time = max(last_on_wall_left_time, last_on_wall_right_time)


# ---- Movement / Run ----
func x_movement(delta: float, lerp_amount := 1.0) -> void:
	# Read input (x_dir already set)
	if x_dir == 0:
		# decelerate
		velocity.x = Vector2(velocity.x, 0).move_toward(Vector2(0,0), deceleration * delta).x
		return

	# target speed based on input
	var target_speed = x_dir * max_speed
	# apply lerp to smooth control (used after wall jump)
	target_speed = lerp(velocity.x, target_speed, lerp_amount)

	# determine accel rate (ground vs air)
	var accel_rate : float
	if last_on_ground_time > 0:
		accel_rate = acceleration if abs(target_speed) > 0.01 else deceleration
	else:
		accel_rate = (acceleration * accel_in_air) if abs(target_speed) > 0.01 else (deceleration * deccel_in_air)

	# apex bonus
	if (is_jumping or is_wall_jumping or _is_jump_falling) and abs(velocity.y) < jump_hang_treshold:
		accel_rate *= jump_hang_accel_mult
		target_speed *= jump_hang_maxspeed_mult

	# conserve momentum if desired
	if do_conserve_momentum and abs(velocity.x) > abs(target_speed) and sign(velocity.x) == sign(target_speed) and abs(target_speed) > 0.01 and last_on_ground_time < 0:
		accel_rate = 0

	# Are we turning? (use turning_acceleration)
	var chosen_accel = acceleration if sign(velocity.x) == sign(target_speed) or velocity.x == 0 else turning_acceleration

	if accel_rate == 0:
		return

	# accelerate toward target
	var speed_dif = target_speed - velocity.x
	var movement = speed_dif * accel_rate * delta
	velocity.x += movement

	# clamp to max speed
	if abs(velocity.x) > max_speed and sign(velocity.x) == sign(target_speed):
		velocity.x = sign(velocity.x) * max_speed

func set_direction(hor_direction) -> void:
	if hor_direction == 0:
		return
	# If your project uses apply_scale, keep it; otherwise use scale:
	# apply_scale(Vector2(hor_direction * face_direction, 1))
	scale = Vector2(hor_direction * face_direction, 1) * scale
	face_direction = hor_direction

# ----- Jump handling -----
func _handle_jumps() -> void:
	# Map old buffer timers too for compatibility
	if jump_coyote_timer > 0:
		last_on_ground_time = max(last_on_ground_time, jump_coyote_timer)

	# If jump pressed while on ground -> normal jump
	if last_on_ground_time > 0 and last_pressed_jump_time > 0 and not is_jumping:
		_perform_jump()
		return

	# Wall jump
	if last_pressed_jump_time > 0 and last_on_wall_time > 0 and last_on_ground_time <= 0 and (not is_wall_jumping or (last_on_wall_right_time > 0 and _last_wall_jump_dir == 1) or (last_on_wall_left_time > 0 and _last_wall_jump_dir == -1)):
		_perform_wall_jump()
		return

	# If released jump while going up -> set jump_cut
	if get_input()["released_jump"] and velocity.y < 0:
		_is_jump_cut = true
		velocity.y -= (jump_cut * velocity.y)

func _perform_jump() -> void:
	# consume buffer/coyote
	last_pressed_jump_time = -1.0
	last_on_ground_time = -1.0
	jump_coyote_timer = -1.0
	is_jumping = true
	_is_jump_cut = false
	_is_jump_falling = false

	# if falling, reduce that momentum (like your original approach)
	if velocity.y > 0:
		velocity.y = 0

	velocity.y = -jump_force

func _perform_wall_jump() -> void:
	last_pressed_jump_time = -1.0
	last_on_ground_time = -1.0
	last_on_wall_right_time = -1.0
	last_on_wall_left_time = -1.0

	is_wall_jumping = true
	is_jumping = false
	_is_jump_cut = false
	_is_jump_falling = false
	_wall_jump_timer = wall_jump_time # <-- start the wall-jump timer (used instead of OS.get_ticks_msec())
	_last_wall_jump_dir = -1 if last_on_wall_right_time > 0 else 1

	var force = Vector2(abs(wall_jump_force.x), -abs(wall_jump_force.y))
	force.x *= _last_wall_jump_dir
	# Reduce horizontal velocity if it would fight against the wall-jump
	if sign(velocity.x) != sign(force.x):
		force.x -= velocity.x

	# if falling, remove downward component so result achieves desired upward impulse
	if velocity.y > 0:
		force.y -= velocity.y

	# apply as instantaneous change to velocity (Impulse-like)
	velocity.x += force.x
	velocity.y = force.y

func _update_slide_state() -> void:
	# slide if on wall, not on ground, not jumping, and pressing toward the wall
	var move_input_x = get_input()["x"]
	var pressing_toward_wall = ((last_on_wall_left_time > 0 and move_input_x < 0) or (last_on_wall_right_time > 0 and move_input_x > 0))
	if (last_on_wall_time > 0) and not is_jumping and not is_wall_jumping and last_on_ground_time <= 0 and pressing_toward_wall:
		is_sliding = true
	else:
		is_sliding = false

# ----- Gravity, fall clamps and slide behavior -----
func _apply_gravity_and_limits(delta: float) -> void:
	var applied_gravity = gravity_acceleration

	# sliding: slow fall
	if is_sliding:
		# cap falling speed to slide_speed (positive number for downward cap)
		if velocity.y > slide_speed:
			velocity.y = slide_speed
		# optionally reduce gravity a bit so it feels sticky
		applied_gravity *= 0.15
		velocity.y += applied_gravity * delta
		return

	# Jump hang (apex)
	if (is_jumping or is_wall_jumping or _is_jump_falling) and abs(velocity.y) < jump_hang_treshold:
		applied_gravity *= jump_hang_gravity_mult

	# Jump cut increases gravity
	if _is_jump_cut:
		applied_gravity *= jump_cut_gravity_mult

	# Fast fall when holding down
	if velocity.y < 0 and get_input()["y"] > 0:
		applied_gravity *= fastfall_gravity_mult
		velocity.y = min(velocity.y + applied_gravity * delta, gravity_max)
	else:
		velocity.y += applied_gravity * delta
		if velocity.y > gravity_max:
			velocity.y = gravity_max

	# if hitting a ceiling: avoid weird small upward values
	if is_on_ceiling():
		velocity.y = jump_hang_treshold + 100.0

	# Reset some flags when falling starts
	if is_jumping and velocity.y > 0:
		is_jumping = false
		_is_jump_falling = true



func update_respawn_position(pos:Vector2):
	_respawn_pos = pos


func die():
	print("DED")
	died.emit()
	_input_locked = true
	await get_tree().create_timer(2.0).timeout
	respawn()
	
func respawn():
	global_position = _respawn_pos
	respawned.emit()
	await get_tree().create_timer(0.5).timeout
	_input_locked = false
