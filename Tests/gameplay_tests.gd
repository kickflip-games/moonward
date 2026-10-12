extends Node

var arena: Node2D
var player: Player
var failures: Array[String] = []
var checks := 0
var death_count := 0
var jumps := 0

func _ready() -> void:
	process_physics_priority = -100
	arena = load("res://Tests/MovementTest.tscn").instantiate()
	add_child(arena)
	player = arena.player
	player.died.connect(func(): death_count += 1)
	player.jumped.connect(func(_wall): jumps += 1)
	run.call_deferred()

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error("FAIL: " + description)
	else:
		print("PASS: " + description)

func tick(count: int = 1) -> void:
	for i in count:
		await get_tree().physics_frame
		await get_tree().process_frame

func place(pos: Vector2, vel: Vector2 = Vector2.ZERO) -> void:
	for action in ["jump", "ui_left", "ui_right", "ui_down"]:
		Input.action_release(action)
	player.update_respawn_position(pos)
	player.respawn()
	player.velocity = vel
	await tick(3)
	player._grace_timer = 0.0

func press_jump() -> void:
	Input.action_press("jump")
	await tick()
	Input.action_release("jump")

func run() -> void:
	await tick(4)
	# Actual floor acceleration and reversal, rather than copies of the formula.
	await place(Vector2(0, -8))
	Input.action_press("ui_right")
	await tick(12)
	check(is_equal_approx(player.velocity.x, 560.0), "Run reaches the preserved 560 px/s speed")
	Input.action_release("ui_right")
	Input.action_press("ui_left")
	await tick(3)
	check(player.velocity.x < 0.0, "Turning acceleration reverses a full-speed ground run in three ticks")
	Input.action_release("ui_left")
	await tick(10)
	check(is_zero_approx(player.velocity.x), "Ground release stops predictably")
	# Test both walls under each directional input: the first push must match.
	for side in [-1, 1]:
		for direction in [-1, 0, 1]:
			await place(Vector2(2143 if side == -1 else 2457, -200))
			if direction != 0:
				Input.action_press("ui_left" if direction < 0 else "ui_right")
			await press_jump()
			check(signf(player.velocity.x) == -side and absf(player.velocity.x) > 600.0 and player.velocity.y < 0.0,
				"Wall %d pushes up/away with input %d" % [side, direction])
			await tick(2)
			check(signf(player.velocity.x) == -side, "Wall push survives early steering on side %d" % side)
	await place(Vector2(2143, -200))
	await press_jump()
	Input.action_press("ui_left")
	await tick(20)
	check(player.velocity.x < 0.0, "Steering returns smoothly after the protected wall push")
	# Current right contact must override stale left-wall memory.
	await place(Vector2(2457, -200))
	player._recent_wall_side = -1
	player.last_on_wall_time = 0.08
	await press_jump()
	check(player.velocity.x < 0.0, "Current contact overrides a remembered opposite wall")
	await place(Vector2(2143, -200))
	var tap_start := player.position.y
	await press_jump()
	var wall_tap_peak := player.position.y
	for i in 30:
		await tick()
		wall_tap_peak = minf(wall_tap_peak, player.position.y)
	check(tap_start - wall_tap_peak > 100.0, "A short wall-jump tap retains a useful minimum rise")
	arena.ground("TightLeft", Vector2(11000 - 16, -300), Vector2(4, 500))
	arena.ground("TightRight", Vector2(11000 + 16, -300), Vector2(4, 500))
	await place(Vector2(11000, -300))
	await press_jump()
	check(player.is_wall_jumping and player.velocity.y < 0.0,
		"Simultaneous wall probes choose a deterministic side without directional input")
	# Repeated real contacts in the narrow shaft, with one fresh press per bounce.
	await place(Vector2(3150, -140))
	var shaft_start := player.position.y
	var previous_side := 0
	var shaft_jumps := 0
	for i in 100:
		var side := player._wall_contact_side
		if side != 0 and side != previous_side:
			Input.action_release("jump")
			await tick()
			Input.action_press("jump")
			await tick()
			previous_side = side
			shaft_jumps += 1
			Input.action_release("ui_left")
			Input.action_release("ui_right")
			Input.action_press("ui_right" if side < 0 else "ui_left")
		await tick()
	check(shaft_jumps >= 4 and player.position.y < shaft_start - 150.0,
		"Repeated alternating wall jumps climb the physical narrow shaft")
	# Leave a real wall; a late press still jumps without a direction chord.
	await place(Vector2(2143, -200))
	player.position.x += 24.0
	await tick(3)
	await press_jump()
	check(player.velocity.x > 0.0 and player.is_wall_jumping, "Wall coyote succeeds three ticks after departure")
	# Real floor coyote after walking beyond the end of the runway.
	await place(Vector2(680, -8))
	player.position.x = 720.0
	await tick(3)
	await press_jump()
	check(player.velocity.y < -1000.0, "Ground coyote succeeds three ticks after leaving the ledge")
	# Buffered landing; release before landing still gives a short jump.
	await place(Vector2(0, -75), Vector2(0, 600))
	var jump_count := jumps
	await press_jump()
	await tick(5)
	check(jumps == jump_count + 1 and player.velocity.y < 0.0, "Landing consumes one buffered jump")
	await tick(60)
	check(jumps == jump_count + 1, "One press cannot generate repeated jumps")
	check(not player._is_jump_cut and not player.is_wall_jumping, "Landing resets jump-cut and wall-jump state")
	# A jump pressed before reaching the wall is buffered too.
	await place(Vector2(2180, -250), Vector2(-400, 0))
	Input.action_press("ui_left")
	await press_jump()
	await tick(6)
	check(player.is_wall_jumping and player.velocity.x > 0.0, "Buffered input fires when a wall is reached")
	# Ceiling collision cancels upward motion without a downward kick.
	await place(Vector2(4200, -8))
	Input.action_press("jump")
	await tick(17)
	check(player.velocity.y >= 0.0 and player.velocity.y < 500.0, "Ceiling ends the jump without a forced bump")
	# Real platform carry: compare rider position to body position over a second.
	var platform: AnimatableBody2D = arena.get_node("MovingPlatform/ActualPlatform")
	await place(platform.global_position + Vector2(0, -24))
	await tick(5)
	var offset := player.global_position.x - platform.global_position.x
	await tick(45)
	check(player.is_on_floor() and absf(player.global_position.x - platform.global_position.x - offset) < 3.0,
		"Built-in platform transport carries a stationary rider without drift")
	check(absf(player.velocity.x) < 1.0, "Platform transport does not accumulate in player run velocity")
	var carried_velocity := player.get_platform_velocity().x
	await press_jump()
	check(absf(player.velocity.x - carried_velocity) < 45.0, "Platform leave velocity is inherited once")
	await place(Vector2(0, -8))
	await tick(6)
	check(absf(player.global_position.x) < 1.0, "Respawn forgets platform transport")
	# Both vertical and rotated spring direction preserve their full launch force.
	await place(Vector2(6100, -80), Vector2(0, 400))
	await tick(8)
	check(player.velocity.y < -2000.0, "Springboard retains its powerful launch")
	check(not player._is_jump_cut, "Spring launch clears previous jump-cut state")
	await place(Vector2(6330, -45), Vector2(0, 400))
	arena.get_node("AngledSpring").can_bounce = true
	arena.get_node("AngledSpring").bounce_player(player)
	check(player.velocity.x > 1100.0 and player.velocity.y < -2000.0, "Rotated spring launches along its visible up direction")
	# The spring's fast vertical motion must remain within the camera frame.
	await place(Vector2(6100, -80), Vector2(0, 400))
	var largest_camera_gap := 0.0
	for i in 55:
		await tick()
		largest_camera_gap = maxf(largest_camera_gap, absf(player.position.y - arena.camera.global_position.y))
	check(largest_camera_gap < get_viewport().get_visible_rect().size.y * 0.4,
		"Camera keeps a high-speed spring launch comfortably inside the frame")
	check(arena.phantom.follow_offset.y >= -220.0 and arena.phantom.follow_offset.y <= -35.0,
		"Camera lookahead stays within configurable vertical bounds")
	# Test empty spaces between spike tips, including rotation and scaling.
	var spikes = load("res://Enemies/Spikes/spikes.tscn").instantiate()
	spikes.position = Vector2(10000, -500)
	spikes.rotation = PI / 2.0
	spikes.scale = Vector2(0.58, 0.58)
	add_child(spikes)
	await tick(2)
	var query := PhysicsPointQueryParameters2D.new()
	query.collision_mask = 4
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.position = spikes.to_global(Vector2(-33, -12))
	check(not player.get_world_2d().direct_space_state.intersect_point(query).is_empty(),
		"A rotated/scaled visible spike tip remains lethal")
	query.position = spikes.to_global(Vector2(-22, -16))
	check(player.get_world_2d().direct_space_state.intersect_point(query).is_empty(),
		"Visible empty gaps between rotated/scaled spike tips are safe")
	spikes.queue_free()
	# Retry and duplicate deaths, including animator state after the old clip ends.
	await place(Vector2(0, -8))
	player._is_jump_cut = true
	player.last_on_wall_time = 0.1
	player.last_pressed_jump_time = 0.12
	var old_deaths := death_count
	player.die()
	player.die()
	player.die()
	check(death_count == old_deaths + 1, "Simultaneous hazards emit one death")
	await tick(23)
	check(not player.is_dead and not player._input_locked, "Retry returns control within 0.4 seconds")
	check(not player._is_jump_cut and player.last_on_wall_time == 0.0 and player.last_pressed_jump_time == 0.0,
		"Respawn clears jump-cut, wall coyote and buffered input")
	await tick(90)
	check(player.get_node("Sprite/Polygon2D").visible, "Old death animation cannot hide a respawned player")
	# Safe long falls no longer cause uncommunicated deaths.
	await place(Vector2(0, -800))
	old_deaths = death_count
	await tick(65)
	check(player.is_on_floor() and death_count == old_deaths, "An 800 px fall onto safe ground is safe")
	await checkpoints_test()
	await turret_test()
	print("RESULT: %d checks, %d failures" % [checks, failures.size()])
	var args = OS.get_cmdline_user_args()
	if "--output" in args:
		var file = FileAccess.open(args[args.find("--output") + 1], FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks": checks, "failures": failures}, "\t"))
	get_tree().quit(0 if failures.is_empty() else 1)

func checkpoints_test() -> void:
	var checkpoints: Array[Checkpoint] = []
	for i in [2, 0, 1]:
		var checkpoint: Checkpoint = load("res://Checkpoint/Checkpoint.tscn").instantiate()
		checkpoint.position = Vector2(20000 - i * 100, -i * 200)
		checkpoint.progression_index = i
		add_child(checkpoint)
		checkpoints.append(checkpoint)
	check(CheckpointManager.checkpoints[0].progression_index == 0 and
		CheckpointManager.checkpoints[2].progression_index == 2, "Checkpoint registration sorts explicit progression, not x")
	var later: Checkpoint = CheckpointManager.checkpoints[1]
	later.activate_for(player)
	var earlier: Checkpoint = CheckpointManager.checkpoints[0]
	earlier.activate_for(player)
	check(CheckpointManager.current_checkpoint == later and player._respawn_pos == later.global_position,
		"An older checkpoint cannot replace the last successful checkpoint")
	CheckpointManager.register_checkpoint(later)
	check(CheckpointManager.checkpoints.size() == 3, "Duplicate checkpoint registration is ignored")
	for checkpoint in checkpoints:
		checkpoint.queue_free()
	await tick(2)
	CheckpointManager._on_scene_changed()
	check(CheckpointManager.checkpoints.is_empty() and CheckpointManager.current_checkpoint_index == -1,
		"Scene changes clear freed checkpoint references")

func turret_test() -> void:
	await place(Vector2(8200, -8))
	var turret = arena.get_node("Turret")
	turret.cooldown_remaining = 0.0
	turret.cancel_charge()
	await tick(1)
	check(turret.is_charging, "Turret acquires with a visible charge state")
	await tick(20)
	check(turret.is_charging and turret.cooldown_remaining == 0.0, "Turret never fires before its half-second warning")
	await tick(12)
	check(turret.cooldown_remaining > 0.0, "Turret fires after the warning completes")
	var original_position: Vector2 = turret.position
	var original_range: float = turret.range
	turret.position.x += 2000.0
	turret.range = 5000.0
	turret.cooldown_remaining = 0.0
	await tick(2)
	check(not turret.is_charging and turret.cooldown_remaining == 0.0,
		"Offscreen turrets cannot acquire or fire without a visible warning")
	turret.position = original_position
	turret.range = original_range
	var projectile: Projectile = load("res://Enemies/Projectile/Projectile.tscn").instantiate()
	projectile.reset(true, 0.025, 400.0, player)
	projectile.position = Vector2(8000, -400)
	projectile.rotation = 0.0
	add_child(projectile)
	await tick(40)
	var heading := projectile.rotation
	player.position = Vector2(8000, -1000)
	await tick(12)
	check(is_equal_approx(projectile.rotation, heading), "Projectile commits to its direction after brief homing")
	projectile.queue_free()
