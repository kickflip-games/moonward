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

# fall damage
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

# wall timers (coyote-style)
var last_on_ground_time : float = 0.0
var last_on_wall_time : float = 0.0
var last_on_wall_left_time : float = 0.0
var last_on_wall_right_time : float = 0.0
var last_pressed_jump_time : float = 0.0

# wall jump params - more diagonal now
@export var wall_jump_force := Vector2(1200, 1000)  # More horizontal, less vertical
@export var wall_jump_time : float = 0.15
@export var wall_jump_run_lerp : float = 0.65

var is_wall_jumping := false
var _wall_jump_timer : float = 0.0
var _last_wall_jump_dir : int = 0

# slide params
@export var slide_speed : float = 80.0
@export var slide_accel : float = 400.0

var is_sliding := false
var _input_locked:=true

# Debug
@export var show_debug_state: bool = true
@onready var debug_label: Label = Label.new()

signal died
signal respawned

# respawn location
var _respawn_pos:Vector2 = Vector2.ZERO


func _ready() -> void:
	_respawn_pos = global_position
	# Ensure raycasts are enabled
	if ray_wall_left:
		ray_wall_left.enabled = true
	if ray_wall_right:
		ray_wall_right.enabled = true
	
	# Setup debug label
	add_child(debug_label)
	debug_label.position = Vector2(-50, -60)
	debug_label.add_theme_font_size_override("font_size", 16)
	debug_label.modulate = Color.YELLOW
	
	respawn()


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
	# Update timers
	_update_timers(delta)

	# Do collision checks
	_collision_checks()

	# Read input and set direction
	x_dir = get_input()["x"]
	if x_dir != 0:
		set_direction(x_dir)

	# Handle jump button buffering
	if get_input()["just_jump"]:
		last_pressed_jump_time = jump_buffer

	# Decide jumps (ground or wall)
	_handle_jumps()

	# Movement (run) - reduce control during wall jump
	var run_lerp = 1.0
	if is_wall_jumping and _wall_jump_timer > 0.0:
		run_lerp = wall_jump_run_lerp
	x_movement(delta, run_lerp)

	# Wall slide detection
	_update_slide_state()

	# Gravity & vertical behavior
	_apply_gravity_and_limits(delta)

	# Platform motion: update and add to velocity before moving
	_update_platform_motion()

	# Move
	move_and_slide()

	# Expire wall-jump state once timer runs out
	if is_wall_jumping and _wall_jump_timer <= 0.0:
		is_wall_jumping = false
		
	# Fall damage check
	if not is_on_floor():
		if not _is_airborne:
			print('just landed')
			_last_grounded_y = position.y
			_is_airborne = true
	else:
		if _is_airborne:
			var fall_height = position.y - _last_grounded_y
			if fall_height > max_fall_height:
				print("Fell to death (height = %s)" % fall_height)
				die()
			_is_airborne = false
	
	# Update debug state
	if show_debug_state:
		_update_debug_label()


func _update_timers(delta: float) -> void:
	jump_coyote_timer = max(jump_coyote_timer - delta, -1.0)
	jump_buffer_timer = max(jump_buffer_timer - delta, -1.0)
	last_on_ground_time = max(last_on_ground_time - delta, -1.0)
	last_on_wall_time = max(last_on_wall_time - delta, -1.0)
	last_on_wall_left_time = max(last_on_wall_left_time - delta, -1.0)
	last_on_wall_right_time = max(last_on_wall_right_time - delta, -1.0)
	last_pressed_jump_time = max(last_pressed_jump_time - delta, -1.0)

	# Decrement wall-jump timer
	if _wall_jump_timer > 0.0:
		_wall_jump_timer = max(_wall_jump_timer - delta, 0.0)


func _collision_checks() -> void:
	# Ground check
	if ground_cast.is_colliding():
		last_on_ground_time = jump_coyote
		jump_coyote_timer = jump_coyote
		is_jumping = false
		_is_jump_falling = false
		
	# Wall checks - fixed for both sides
	# Right wall check
	if ray_wall_right.is_colliding():
		last_on_wall_right_time = jump_coyote
		
	# Left wall check
	if ray_wall_left.is_colliding():
		last_on_wall_left_time = jump_coyote
		
	# Update combined wall time
	last_on_wall_time = max(last_on_wall_left_time, last_on_wall_right_time)


func x_movement(delta: float, lerp_amount := 1.0) -> void:
	if x_dir == 0:
		# Decelerate
		velocity.x = Vector2(velocity.x, 0).move_toward(Vector2(0,0), deceleration * delta).x
		return

	# Target speed
	var target_speed = x_dir * max_speed
	# Apply lerp (useful for wall jump control)
	target_speed = lerp(velocity.x, target_speed, lerp_amount)

	# Determine accel rate
	var accel_rate : float
	if last_on_ground_time > 0:
		accel_rate = acceleration if abs(target_speed) > 0.01 else deceleration
	else:
		accel_rate = (acceleration * accel_in_air) if abs(target_speed) > 0.01 else (deceleration * deccel_in_air)

	# Apex bonus
	if (is_jumping or is_wall_jumping or _is_jump_falling) and abs(velocity.y) < jump_hang_treshold:
		accel_rate *= jump_hang_accel_mult
		target_speed *= jump_hang_maxspeed_mult

	# Conserve momentum
	if do_conserve_momentum and abs(velocity.x) > abs(target_speed) and sign(velocity.x) == sign(target_speed) and abs(target_speed) > 0.01 and last_on_ground_time < 0:
		accel_rate = 0

	# Turning acceleration
	var chosen_accel = acceleration if sign(velocity.x) == sign(target_speed) or velocity.x == 0 else turning_acceleration

	if accel_rate == 0:
		return

	# Accelerate (stable approach to prevent oscillations)
	velocity.x = move_toward(velocity.x, target_speed, accel_rate * delta)

	# Clamp to max speed
	if abs(velocity.x) > max_speed and sign(velocity.x) == sign(target_speed):
		velocity.x = sign(velocity.x) * max_speed


func set_direction(hor_direction) -> void:
	if hor_direction == 0:
		return
	# scale = Vector2(hor_direction * face_direction, 1) * scale
	face_direction = hor_direction


func _handle_jumps() -> void:
	# Map buffer timers
	if jump_coyote_timer > 0:
		last_on_ground_time = max(last_on_ground_time, jump_coyote_timer)

	# Ground jump
	if last_on_ground_time > 0 and last_pressed_jump_time > 0 and not is_jumping:
		_perform_jump()
		return

	# Wall jump - with better spam prevention
	var can_wall_jump = last_pressed_jump_time > 0 and last_on_wall_time > 0 and last_on_ground_time <= 0
	
	# Check if trying to jump from a different wall
	var different_wall = true
	if is_wall_jumping and _wall_jump_timer > 0:
		different_wall = (last_on_wall_right_time > 0 and _last_wall_jump_dir == 1) or \
						(last_on_wall_left_time > 0 and _last_wall_jump_dir == -1)
	
	if can_wall_jump and different_wall:
		_perform_wall_jump()
		return

	# Jump cut
	if get_input()["released_jump"] and velocity.y < 0:
		_is_jump_cut = true
		velocity.y -= (jump_cut * velocity.y)


func _perform_jump() -> void:
	# Clear timers
	last_pressed_jump_time = -1.0
	last_on_ground_time = -1.0
	jump_coyote_timer = -1.0
	
	# Set states
	is_jumping = true
	_is_jump_cut = false
	_is_jump_falling = false

	# Reset downward velocity
	if velocity.y > 0:
		velocity.y = 0

	velocity.y = -jump_force


func _perform_wall_jump() -> void:
	# Figure out direction BEFORE clearing timers
	var dir = 1 if last_on_wall_left_time > 0 else -1
	print("jump dir: ", dir)

	# Clear timers
	last_pressed_jump_time = -1.0
	last_on_ground_time = -1.0
	last_on_wall_right_time = -1.0
	last_on_wall_left_time = -1.0

	# Set states
	is_wall_jumping = true
	is_jumping = true   # treat it as a jump
	_is_jump_cut = false
	_is_jump_falling = false
	_wall_jump_timer = wall_jump_time
	_last_wall_jump_dir = dir

	print("before wall jump: ", velocity)

	# Apply wall jump force directly
	var force = Vector2(wall_jump_force.x * dir, -wall_jump_force.y)
	velocity.x = force.x
	velocity.y = force.y

	print("executed wall jump: ", velocity)


func _update_slide_state() -> void:
	var move_input_x = get_input()["x"]
	
	# Check both walls properly
	var on_left_wall = last_on_wall_left_time > 0
	var on_right_wall = last_on_wall_right_time > 0
	
	# Pressing toward the wall means:
	# - Pressing LEFT when on LEFT wall
	# - Pressing RIGHT when on RIGHT wall
	var pressing_toward_wall = (on_left_wall and move_input_x < 0) or (on_right_wall and move_input_x > 0)
	
	if (last_on_wall_time > 0) and not is_jumping and not is_wall_jumping and \
	   last_on_ground_time <= 0 and pressing_toward_wall:
		is_sliding = true
		_last_grounded_y = position.y
	else:
		is_sliding = false


func _apply_gravity_and_limits(delta: float) -> void:
	var applied_gravity = gravity_acceleration

	# Wall sliding: smooth controlled fall
	if is_sliding:
		# Smoothly approach slide speed
		if velocity.y < slide_speed:
			velocity.y += slide_accel * delta
			if velocity.y > slide_speed:
				velocity.y = slide_speed
		elif velocity.y > slide_speed:
			velocity.y = move_toward(velocity.y, slide_speed, slide_accel * 2 * delta)
		return

	# Jump hang (apex)
	if (is_jumping or is_wall_jumping or _is_jump_falling) and abs(velocity.y) < jump_hang_treshold:
		applied_gravity *= jump_hang_gravity_mult

	# Jump cut
	if _is_jump_cut:
		applied_gravity *= jump_cut_gravity_mult

	# Fast fall
	if velocity.y < 0 and get_input()["y"] > 0:
		applied_gravity *= fastfall_gravity_mult
		velocity.y = min(velocity.y + applied_gravity * delta, gravity_max)
	else:
		velocity.y += applied_gravity * delta
		if velocity.y > gravity_max:
			velocity.y = gravity_max

	# Ceiling bump
	if is_on_ceiling():
		velocity.y = jump_hang_treshold + 100.0

	# Update jump states
	if is_jumping and velocity.y > 0:
		is_jumping = false
		_is_jump_falling = true


func _update_debug_label():
	var state = "IDLE"
	
	if _input_locked:
		state = "LOCKED"
	elif is_sliding:
		state = "WALL SLIDE"
	elif is_wall_jumping:
		state = "WALL JUMP"
	elif is_jumping:
		state = "JUMPING"
	elif _is_jump_falling:
		state = "FALLING"
	elif last_on_ground_time > 0:
		if abs(velocity.x) > 10:
			state = "RUNNING"
		else:
			state = "IDLE"
	else:
		state = "AIRBORNE"
	
	# Add wall side info when on wall
	if last_on_wall_left_time > 0:
		state += " (L)"
	elif last_on_wall_right_time > 0:
		state += " (R)"
	
	debug_label.text = state
	debug_label.visible = show_debug_state


# Function to check if player is in a state where somersault should play
func should_play_somersault() -> bool:
	# Don't somersault when sliding or wall jumping
	return is_jumping and not is_sliding and not is_wall_jumping and abs(velocity.y) > 100


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
	velocity = Vector2.ZERO
	respawned.emit()
	await get_tree().create_timer(0.5).timeout
	_input_locked = false



var _current_platform: AnimatableBody2D = null
var _last_platform_position: Vector2 = Vector2.ZERO
var _platform_velocity: Vector2 = Vector2.ZERO
var _was_on_floor: bool = false

func _update_platform_motion() -> void:
	var now_on_floor = is_on_floor()
	if now_on_floor:
		var platform: AnimatableBody2D = _get_floor_platform()
		if platform and platform.is_in_group("moving_platform"):
			# If just landed or switched platform, reset tracking to avoid teleport
			if platform != _current_platform or not _was_on_floor:
				_current_platform = platform
				_last_platform_position = platform.global_position
				_platform_velocity = Vector2.ZERO
			else:
				_platform_velocity = (platform.global_position - _last_platform_position) / get_physics_process_delta_time()
				_last_platform_position = platform.global_position
		else:
			_current_platform = null
			_platform_velocity = Vector2.ZERO
	else:
		_current_platform = null
		_platform_velocity = Vector2.ZERO

	# Add platform velocity to player velocity
	if _platform_velocity != Vector2.ZERO:
		velocity += _platform_velocity

	_was_on_floor = now_on_floor

func _get_floor_platform() -> AnimatableBody2D:
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		if collision and collision.get_normal().y < -0.7:
			return collision.get_collider()
	return null
