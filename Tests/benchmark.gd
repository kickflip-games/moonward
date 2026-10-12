extends Node

## Shared with the original archived project, so before/after use the actual controllers.
var player: Player
var arena: Node2D
var results := {}
var death_count := 0

func _ready() -> void:
	arena = load("res://Tests/MovementTest.tscn").instantiate()
	add_child(arena)
	player = arena.player
	player.died.connect(func(): death_count += 1)
	run.call_deferred()

func tick(count: int = 1) -> void:
	for i in count:
		await get_tree().physics_frame
		await get_tree().process_frame

func place(pos: Vector2) -> void:
	for action in ["jump", "ui_left", "ui_right"]:
		Input.action_release(action)
	player.update_respawn_position(pos)
	player.respawn()
	# Let the original's spawn timer complete as well.
	await tick(40)
	player.global_position = pos
	player.velocity = Vector2.ZERO
	await tick(10)

func run() -> void:
	await tick(40)
	await place(Vector2(0, -8))
	Input.action_press("ui_right")
	var frames_to_speed := 0
	while player.velocity.x < 559.0 and frames_to_speed < 60:
		await tick()
		frames_to_speed += 1
	results.run_acceleration_frames = frames_to_speed
	Input.action_release("ui_right")
	Input.action_press("ui_left")
	var reversal := 0
	while player.velocity.x >= 0.0 and reversal < 60:
		await tick()
		reversal += 1
	results.ground_reversal_frames = reversal
	for hold_frames in [1, 60]:
		await place(Vector2(0, -8))
		var starting_y := player.position.y
		var peak := starting_y
		Input.action_press("jump")
		for i in 65:
			if i == hold_frames:
				Input.action_release("jump")
			await tick()
			peak = minf(peak, player.position.y)
		results["jump_height_hold_%d_frames" % hold_frames] = starting_y - peak
	for side in [-1, 1]:
		for input_dir in [-1, 0, 1]:
			await place(Vector2(2143 if side < 0 else 2457, -200))
			if input_dir != 0:
				Input.action_press("ui_left" if input_dir < 0 else "ui_right")
			Input.action_press("jump")
			await tick()
			results["wall_%d_input_%d_initial_vx" % [side, input_dir]] = player.velocity.x
			await tick(5)
			results["wall_%d_input_%d_vx_after_100ms" % [side, input_dir]] = player.velocity.x
	await place(Vector2(0, -8))
	var initial_deaths := death_count
	player.die()
	player.die()
	player.die()
	results.deaths_emitted_for_three_calls = death_count - initial_deaths
	var retry := 0
	while player._input_locked and retry < 120:
		await tick()
		retry += 1
	results.death_to_control_frames = retry
	await place(Vector2(2143, -200))
	var wall_start := player.position.y
	var wall_peak := wall_start
	Input.action_press("jump")
	await tick()
	Input.action_release("jump")
	for i in 50:
		await tick()
		wall_peak = minf(wall_peak, player.position.y)
	results.wall_jump_tap_rise = wall_start - wall_peak
	var args = OS.get_cmdline_user_args()
	var output = args[args.find("--output") + 1]
	var file = FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "\t"))
	print(JSON.stringify(results))
	# Allow original pending animation/death callbacks to finish before teardown.
	await tick(90)
	get_tree().quit()
