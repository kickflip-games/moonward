extends Node2D

@export var player_path: NodePath
@onready var player: CharacterBody2D = get_node(player_path)
@onready var animator: AnimationPlayer = $"../AnimationPlayer"
@onready var polygon: Polygon2D = $Polygon2D  

# Audio references
@onready var jump_sfx: AudioStreamPlayer2D = $"../Sfx/JumpSFX"
@onready var land_sfx: AudioStreamPlayer2D = $"../Sfx/LandSFX"
@onready var footstep_sfx: AudioStreamPlayer2D = $"../Sfx/FootstepSFX"
@onready var wall_slide_sfx: AudioStreamPlayer2D = $"../Sfx/WallslideSFX"
@onready var death_sfx: AudioStreamPlayer2D = $"../Sfx/DeathSFX"
@onready var spawn_sfx: AudioStreamPlayer2D = $"../Sfx/SpawnSFX"

# Particle references - using CPUParticles2D for web compatibility
@onready var jump_particles: CPUParticles2D = $"../ParticleFx/JumpFx"
@onready var land_particles: CPUParticles2D = $"../ParticleFx/LandFx"
@onready var run_particles: CPUParticles2D = $"../ParticleFx/RunFx"
@onready var wall_slide_particles: CPUParticles2D = $"../ParticleFx/WallslideFx"
@onready var death_particles: CPUParticles2D = $"../ParticleFx/DeathFx"
@onready var spawn_particles: CPUParticles2D = $"../ParticleFx/SpawnFx"

# Trail references
@onready var somersault_trail: Line2D = $"../Trails/SomersaultTrail"
@onready var speed_trail: Line2D = $"../Trails/SpeedTrail"


# Animation constants
const IDLE_ANIM = "Idle"
const RUN_ANIM = "Run"
const JUMP_ANIM = "Jump"
const FALL_ANIM = "Airborne"
const LAND_ANIM = "Land"
const WALL_SLIDE_ANIM = "WallSlide"
const WALL_JUMP_ANIM = "WallJump"
const SPAWN_ANIM = "Spawn"
const FALL_DEATH_ANIM = "FallDeath"

# State tracking
var previous_velocity := Vector2.ZERO
var previous_grounded := false
var previous_wall_sliding := false
var current_animation := ""
var animation_locked := false
var lock_timer := 0.0
var is_dead := false

# Rotation and lean system
var target_rotation_degrees := 0.0
var somersault_speed_degrees := 0.0

# FX state tracking
var footstep_timer := 0.0
var footstep_interval := 0.3  # Time between footstep sounds
var trail_points: Array[Vector2] = []
var max_trail_points := 20

# Animation priorities (higher = more important)
var animation_priorities = {
	SPAWN_ANIM: 100,
	FALL_DEATH_ANIM: 90,
	WALL_JUMP_ANIM: 80,
	LAND_ANIM: 70,
	JUMP_ANIM: 60,
	WALL_SLIDE_ANIM: 50,
	FALL_ANIM: 40,
	RUN_ANIM: 30,
	IDLE_ANIM: 10
}

# Default lock durations for specific animations
var default_lock_durations = {
	LAND_ANIM: 0.3,
	JUMP_ANIM: 0.2,
	WALL_JUMP_ANIM: 0.4,
	SPAWN_ANIM: 2.0,
	FALL_DEATH_ANIM: 1.0
}

func _ready() -> void:
	if player == null:
		push_error("PlayerSpriteAnimator: player_path is not set or invalid!")
		set_process(false)
		return
	
	_setup_animation_connections()
	_setup_fx_systems()
	
	if player.has_signal("died"):
		player.died.connect(_on_player_died)
	if player.has_signal("respawned"):
		player.respawned.connect(_on_player_respawned)
	
	play_animation(SPAWN_ANIM)

func _setup_fx_systems() -> void:
	# Setup CPU particles with web-friendly settings
	_setup_jump_particles()
	_setup_land_particles()
	_setup_run_particles()
	_setup_wall_slide_particles()
	_setup_death_particles()
	_setup_spawn_particles()
	
	# Setup trails
	if somersault_trail:
		somersault_trail.width = 12.0
		somersault_trail.default_color = Color.WHITE
		somersault_trail.default_color.a = 0.6
		
	
	if speed_trail:
		speed_trail.width = 12.0
		speed_trail.default_color = Color.WHITE
		speed_trail.default_color.a = 0.3

func _setup_jump_particles() -> void:
	if not jump_particles:
		return
	jump_particles.emitting = false
	jump_particles.amount = 15
	jump_particles.lifetime = 0.6
	jump_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	jump_particles.emission_sphere_radius = 8.0
	jump_particles.direction = Vector2(-1, 0)
	jump_particles.initial_velocity_min = 50.0
	jump_particles.initial_velocity_max = 100.0
	jump_particles.angular_velocity_min = -180.0
	jump_particles.angular_velocity_max = 180.0
	jump_particles.scale_amount_min = 0.5
	jump_particles.scale_amount_max = 1.0

func _setup_land_particles() -> void:
	if not land_particles:
		return
	land_particles.emitting = false
	land_particles.amount = 20
	land_particles.lifetime = 0.8
	land_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	land_particles.emission_sphere_radius = 12.0
	land_particles.direction = Vector2( -1, 0)
	land_particles.spread = 45.0
	land_particles.initial_velocity_min = 30.0
	land_particles.initial_velocity_max = 80.0
	land_particles.gravity = Vector2( 98, 0)

func _setup_run_particles() -> void:
	if not run_particles:
		return
	run_particles.emitting = false
	run_particles.amount = 8
	run_particles.lifetime = 0.4
	run_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	run_particles.emission_sphere_radius = 4.0
	run_particles.direction = Vector2( -1, 0)
	run_particles.spread = 30.0
	run_particles.initial_velocity_min = 20.0
	run_particles.initial_velocity_max = 40.0
	run_particles.scale_amount_min = 0.3
	run_particles.scale_amount_max = 0.6

func _setup_wall_slide_particles() -> void:
	if not wall_slide_particles:
		return
	wall_slide_particles.emitting = false
	wall_slide_particles.amount = 12
	wall_slide_particles.lifetime = 0.5
	wall_slide_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
	wall_slide_particles.direction = Vector2(0, 0)  # Will be flipped based on wall side
	wall_slide_particles.spread = 20.0
	wall_slide_particles.initial_velocity_min = 25.0
	wall_slide_particles.initial_velocity_max = 50.0
	wall_slide_particles.gravity = Vector2(49, 0)

func _setup_death_particles() -> void:
	if not death_particles:
		return
	death_particles.emitting = false
	death_particles.amount = 30
	death_particles.lifetime = 1.5
	death_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	death_particles.emission_sphere_radius = 16.0
	death_particles.direction = Vector2( -1, 0)
	death_particles.spread = 180.0
	death_particles.initial_velocity_min = 50.0
	death_particles.initial_velocity_max = 150.0
	death_particles.gravity = Vector2(98, 0)
	death_particles.scale_amount_min = 0.5
	death_particles.scale_amount_max = 1.5

func _setup_spawn_particles() -> void:
	if not spawn_particles:
		return
	spawn_particles.emitting = false
	spawn_particles.amount = 25
	spawn_particles.lifetime = 1.0
	spawn_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	spawn_particles.emission_sphere_radius = 20.0
	spawn_particles.direction = Vector2( 0, 0)
	spawn_particles.spread = 180.0
	spawn_particles.initial_velocity_min = 30.0
	spawn_particles.initial_velocity_max = 80.0
	spawn_particles.gravity = Vector2(-49, 0)  # Negative gravity for upward float
	spawn_particles.scale_amount_min = 0.8
	spawn_particles.scale_amount_max = 1.2

func _process(delta: float) -> void:
	if player == null:
		return
		
	# Update lock timer
	if animation_locked:
		lock_timer -= delta
		if lock_timer <= 0:
			animation_locked = false
	
	# Update sprite direction
	if player.face_direction != 0:
		var target_scale = player.face_direction
		if scale.x != target_scale:
			scale.x = target_scale
	
	# Update animations and FX
	_update_animation()
	_apply_animation_lean()
	_update_sprite_rotation(delta)
	_update_fx_systems(delta)
	
	# Ensure polygon stays hidden while dead
	if is_dead and polygon.visible:
		polygon.hide()
	
	# Store previous frame data
	previous_velocity = player.velocity
	previous_grounded = player.is_on_floor()
	previous_wall_sliding = player.is_sliding

func _update_fx_systems(delta: float) -> void:
	_update_footsteps(delta)
	_update_wall_slide_fx()
	_update_trails(delta)
	_update_run_particles()

func _update_footsteps(delta: float) -> void:
	if current_animation == RUN_ANIM and player.is_on_floor():
		footstep_timer -= delta
		if footstep_timer <= 0:
			_play_footstep_fx()
			# Adjust footstep interval based on speed
			var speed_factor = abs(player.velocity.x) / 400.0
			footstep_interval = lerp(0.4, 0.2, speed_factor)
			footstep_timer = footstep_interval
	else:
		footstep_timer = 0.0

func _update_wall_slide_fx() -> void:
	if current_animation == WALL_SLIDE_ANIM:
		if not wall_slide_sfx.playing:
			wall_slide_sfx.play()
		if wall_slide_particles:
			wall_slide_particles.emitting = true
			# Position based on which wall we're on
			if player.last_on_wall_left_time > 0:
				wall_slide_particles.position.x = -16  # Left wall
				wall_slide_particles.direction = Vector2(1, 0)  # Particles go right
			else:  # Right wall
				wall_slide_particles.position.x = 16  # Right wall
				wall_slide_particles.direction = Vector2(-1, 0)  # Particles go left
	else:
		if wall_slide_sfx.playing:
			wall_slide_sfx.stop()
		if wall_slide_particles:
			wall_slide_particles.emitting = false

func _update_trails(delta: float) -> void:
	# Somersault trail during airborne rotation
	if somersault_speed_degrees != 0.0:
		_add_trail_point(somersault_trail)
		if somersault_trail:
			somersault_trail.visible = true
	else:
		if somersault_trail:
			_fade_trail(somersault_trail, delta)
	
	# Speed trail during fast running
	if current_animation == RUN_ANIM and abs(player.velocity.x) > 300:
		_add_trail_point(speed_trail)
		if speed_trail:
			speed_trail.visible = true
	else:
		if speed_trail:
			_fade_trail(speed_trail, delta)

func _add_trail_point(trail: Line2D) -> void:
	if not trail:
		return
		
	var current_pos = global_position
	trail.add_point(current_pos)
	
	# Limit trail length
	if trail.get_point_count() > max_trail_points:
		trail.remove_point(0)

func _fade_trail(trail: Line2D, delta: float) -> void:
	if not trail:
		return

	# Faster fade by removing multiple points
	var points_to_remove = clampi(int(delta * 30), 1, trail.get_point_count())

	for i in range(points_to_remove):
		if trail.get_point_count() == 0:
			break
		trail.remove_point(0)

	if trail.get_point_count() == 0:
		trail.visible = false

func _update_run_particles() -> void:
	if current_animation == RUN_ANIM and player.is_on_floor():
		if run_particles and not run_particles.emitting:
			run_particles.emitting = true
			run_particles.position.y = 16  # At feet level
	else:
		if run_particles:
			run_particles.emitting = false

# Rest of your animation system...
func _update_animation() -> void:
	var desired_animation = _get_desired_animation()
	
	if desired_animation != current_animation and not animation_locked:
		_on_state_change(current_animation, desired_animation)
		play_animation(desired_animation)

func _on_state_change(old_anim: String, new_anim: String) -> void:
	# Handle FX for state transitions
	_handle_fx_transition(old_anim, new_anim)
	
	# Existing rotation logic...
	if _was_grounded_now_airborne(old_anim, new_anim):
		var horizontal_speed = abs(player.velocity.x)
		var somersault_threshold = 150.0
		
		if horizontal_speed > somersault_threshold:
			var base_somersault_rate = 360.0
			var speed_factor = horizontal_speed / 400.0
			somersault_speed_degrees = base_somersault_rate * speed_factor * sign(player.velocity.x)
		else:
			somersault_speed_degrees = 0.0
			rotation_degrees = 0.0

	if _is_grounded_state(new_anim):
		somersault_speed_degrees = 0.0
		rotation_degrees = 0.0
		target_rotation_degrees = 0.0

func _handle_fx_transition(old_anim: String, new_anim: String) -> void:
	match new_anim:
		JUMP_ANIM:
			_play_jump_fx()
		LAND_ANIM:
			_play_land_fx()
		WALL_JUMP_ANIM:
			_play_wall_jump_fx()
		FALL_DEATH_ANIM:
			_play_death_fx()
		SPAWN_ANIM:
			_play_spawn_fx()

func _play_jump_fx() -> void:
	if jump_sfx:
		jump_sfx.pitch_scale = 1.0
		jump_sfx.play()
	if jump_particles:
		jump_particles.position.y = 16  # At feet level
		jump_particles.restart()

func _play_land_fx() -> void:
	if land_sfx:
		# Vary pitch based on fall speed
		var fall_speed = abs(previous_velocity.y)
		land_sfx.pitch_scale = clamp(0.8 + (fall_speed / 500.0), 0.8, 1.3)
		land_sfx.play()
	if land_particles:
		land_particles.position.y = 16
		land_particles.restart()

func _play_wall_jump_fx() -> void:
	if jump_sfx:
		jump_sfx.pitch_scale = 1.2  # Higher pitch for wall jump
		jump_sfx.play()
	if jump_particles:
		jump_particles.position.x = 16 * sign(player.face_direction)
		jump_particles.position.y = 0
		jump_particles.restart()

func _play_footstep_fx() -> void:
	if footstep_sfx:
		footstep_sfx.pitch_scale = randf_range(0.9, 1.1)  # Vary pitch
		footstep_sfx.play()
	# Small particle burst for footstep
	if run_particles:
		run_particles.restart()

func _play_death_fx() -> void:
	if death_sfx:
		death_sfx.play()
	if death_particles:
		death_particles.restart()

func _play_spawn_fx() -> void:
	if spawn_sfx:
		spawn_sfx.play()
	if spawn_particles:
		spawn_particles.restart()

# [Rest of your existing animation code remains the same...]
func _was_grounded_now_airborne(old_anim: String, new_anim: String) -> bool:
	var grounded_states = [RUN_ANIM, IDLE_ANIM, LAND_ANIM]
	var airborne_states = [JUMP_ANIM, FALL_ANIM]
	return old_anim in grounded_states and new_anim in airborne_states

func _is_grounded_state(anim: String) -> bool:
	return anim in [LAND_ANIM, IDLE_ANIM, RUN_ANIM, FALL_DEATH_ANIM]

func _get_desired_animation() -> String:
	if _should_play_death_animation():
		return FALL_DEATH_ANIM
	
	if _just_landed():
		return LAND_ANIM
	
	if player.is_wall_jumping:
		return WALL_JUMP_ANIM
	
	if player.is_sliding:
		return WALL_SLIDE_ANIM
	
	if not player.is_on_floor():
		if player.velocity.y > 50:
			return FALL_ANIM
		elif player.velocity.y < -50:
			return JUMP_ANIM
		else:
			return current_animation if current_animation == JUMP_ANIM or current_animation == FALL_ANIM else JUMP_ANIM
	
	if player.is_on_floor():
		if abs(player.velocity.x) > 50:
			return RUN_ANIM
		else:
			return IDLE_ANIM
	
	return IDLE_ANIM

func _just_landed() -> bool:
	return not previous_grounded and player.is_on_floor() and previous_velocity.y > 100

func _should_play_death_animation() -> bool:
	return false

func _apply_animation_lean():
	if current_animation == FALL_DEATH_ANIM or current_animation == SPAWN_ANIM:
		target_rotation_degrees = 0.0
		somersault_speed_degrees = 0.0
		return
		
	if somersault_speed_degrees == 0.0:
		match current_animation:
			RUN_ANIM:
				var lean_angle = -80.0
				var movement_direction = sign(player.velocity.x)
				if movement_direction != 0:
					target_rotation_degrees = lean_angle * movement_direction
				else:
					target_rotation_degrees = 0.0
			JUMP_ANIM:
				var movement_direction = sign(player.velocity.x)
				target_rotation_degrees = -5.0 * movement_direction if movement_direction != 0 else 0.0
			FALL_ANIM:
				var movement_direction = sign(player.velocity.x)
				target_rotation_degrees = 5.0 * movement_direction if movement_direction != 0 else 0.0
			WALL_SLIDE_ANIM:
				target_rotation_degrees = -5.0 * sign(player.face_direction)
			_:
				target_rotation_degrees = 0.0

func _update_sprite_rotation(delta: float):
	if current_animation == FALL_DEATH_ANIM or current_animation == SPAWN_ANIM or current_animation == WALL_SLIDE_ANIM:
		rotation_degrees = 0.0
		somersault_speed_degrees = 0.0
		target_rotation_degrees = 0.0
		return
	
	if somersault_speed_degrees != 0.0:
		rotation_degrees += somersault_speed_degrees * delta
	else:
		rotation_degrees = lerp_angle(rotation_degrees, target_rotation_degrees, 10.0 * delta)

func play_animation(anim_name: String, lock_duration: float = -1.0) -> void:
	#print("ANIM : ", anim_name, ' [frame: ', Engine.get_frames_drawn(), "] pos: ", player.position)
	if not animator.has_animation(anim_name):
		push_warning("Animation '%s' not found!" % anim_name)
		return
	
	if animation_locked and current_animation in animation_priorities and anim_name in animation_priorities:
		if animation_priorities[current_animation] > animation_priorities[anim_name]:
			return
	
	current_animation = anim_name
	animator.play(anim_name)
	
	var actual_lock_duration = lock_duration
	if lock_duration < 0 and anim_name in default_lock_durations:
		actual_lock_duration = default_lock_durations[anim_name]
	elif lock_duration < 0:
		actual_lock_duration = 0.0
	
	if actual_lock_duration > 0:
		animation_locked = true
		lock_timer = actual_lock_duration

func _on_player_died() -> void:
	is_dead = true
	death_particles.emitting = true
	play_animation(FALL_DEATH_ANIM)
	await animator.animation_finished
	polygon.hide()

func _on_player_respawned() -> void:
	is_dead = false
	polygon.show()
	play_animation(SPAWN_ANIM)
	await animator.animation_finished
	polygon.show()

func _on_animation_finished(anim_name: String) -> void:
	# Only unlock if the finished animation is the current one
	if anim_name == current_animation:
		animation_locked = false
		lock_timer = 0.0

func _setup_animation_connections() -> void:
	if animator and animator.has_signal("animation_finished"):
		animator.animation_finished.connect(_on_animation_finished)
