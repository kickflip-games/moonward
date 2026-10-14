extends Node
var world: Node2D
var player: Player
var failures: Array[String] = []
var checks := 0
func _ready() -> void:run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("FAIL: " + message)
	else:print("PASS: " + message)
func ticks(n: int = 1) -> void:
	for i in n:
		await get_tree().physics_frame
		await get_tree().process_frame
func release() -> void:
	for action in ["jump", "ui_left", "ui_right"]:Input.action_release(action)
func spawn(at: Vector2) -> void:
	release()
	player.update_respawn_position(at)
	player.respawn()
	await ticks(8)
func jump_to(at: Vector2, width: float, moving: Node2D = null, vertical_frames: int = 0) -> bool:
	var trace: Array = []
	var initial_y := player.global_position.y
	release()
	var direction := "ui_right" if at.x > player.global_position.x else "ui_left"
	if vertical_frames == 0:
		Input.action_press(direction)
		await ticks(6)
	else:
		await ticks(2)
	Input.action_press("jump")
	for frame in 85:
		var target := moving.global_position + Vector2(0, -16) if moving else at
		var dx := target.x - player.global_position.x - player.velocity.x * .045
		Input.action_release("ui_left");Input.action_release("ui_right")
		if frame >= vertical_frames and absf(dx) > 6:Input.action_press("ui_right" if dx > 0 else "ui_left")
		await ticks()
		if frame % 5 == 0:trace.append([frame, player.position, player.velocity])
		if player.is_dead:break
		if frame > 7 and player.is_on_floor() and absf(player.global_position.x - target.x) < width / 2 and absf(player.global_position.y - (target.y - 8)) < 8:
			release()
			return true
		if player.global_position.y > initial_y + 180:break
	release()
	print("JUMP MISSED: ", at, " player=", player.global_position, " trace=", trace if moving or at.y == -6336 else [])
	return false
func run() -> void:
	for cycle in 2:
		world = load("res://World/World.tscn").instantiate()
		add_child(world)
		player = world.get_node("Player")
		await ticks(5)
		CheckpointManager._on_scene_changed()
		world.get_node("Map/WinZone").monitoring = false
		check(world.has_node("Map/GameLayer") and not world.has_node("Map/Rooms"), "Main game uses the original continuous tower")
		check(CheckpointManager.checkpoints.size() == 13, "Thirteen chapter checkpoints register on load %d" % cycle)
		for i in 13:
			var checkpoint: Checkpoint = CheckpointManager.checkpoints[i]
			check(checkpoint.progression_index == i, "Checkpoint order %d" % i)
			checkpoint.activate_for(player)
			player.respawn()
			await ticks(15)
			check(not player.is_dead and player.is_on_floor(), "Checkpoint %d has safe footing" % i)
		if cycle == 0:
			await traversal()
			var baseline_world = load("res://World/LegacyWorld.tscn").instantiate()
			var original = baseline_world.get_node("Map")
			var layer: TileMapLayer = world.get_node("Map/GameLayer")
			var retained := true
			for cell in original.get_node("GameLayer").get_used_cells():
				var destination: Vector2i = cell - Vector2i(0, 72) if cell.y * 32 < -4192 else cell
				if layer.get_cell_atlas_coords(destination) != original.get_node("GameLayer").get_cell_atlas_coords(cell):retained = false
			check(retained, "Every original terrain cell survives the additive insertion")
			for container in ["Platforms", "Spikes", "Turrets"]:
				for node in original.get_node(container).get_children():
					var path: String = "Map/" + container + "/" + str(node.name)
					var expected: Vector2 = node.position
					if expected.y + original.get_node(container).position.y < -4192:expected.y -= 2304
					check(world.has_node(path) and world.get_node(path).position.is_equal_approx(expected), "Original mechanism retained at correct height: " + str(node.name))
			baseline_world.free()
			check(world.get_node("HazardRoomFrame").position.y == -10134, "Original hazard camera framing moves with the upper tower")
			check(world.get_node("Map/WinZone").position == Vector2(-1032, -12322), "Original summit translated above the added chapter")
			world.get_node("Map/WinZone").trigger_win(player)
			check(player._input_locked, "Integrated tower reaches the original win flow")
		world.queue_free()
		await ticks(4)
		CheckpointManager._on_scene_changed()
	check(CheckpointManager.checkpoints.is_empty(), "Reload clears shrine references")
	print("INTEGRATED TOWER RESULT: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
func traversal() -> void:
	# A continuous stair climb with real collapse timers, no teleport between jumps.
	await spawn(Vector2(-962, -4139))
	var stair_ok := true
	for at in [Vector2(-1216, -4288), Vector2(-1440, -4432), Vector2(-1216, -4576), Vector2(-1472, -4720), Vector2(-1600, -4800)]:
		if not await jump_to(at, 96):
			stair_ok = false
			break
	check(stair_ok, "Collapsing stair completed continuously with active break timers")
	# Waiting on the narrow planks must have a real cost.
	await ticks(210)
	await spawn(Vector2(-1216, -4296))
	await ticks(36)
	check(world.get_node("Map/Platforms/Stair01").is_broken, "Stair foothold collapses when the player waits")
	await spawn(Vector2(-1600, -4808))
	var lift: Node2D = world.get_node("Map/Platforms/Counterweight/ActualPlatform")
	var boarded := false
	for attempt in 3:
		await spawn(Vector2(-1600, -4808))
		for frame in 240:
			if lift.global_position.y > -4890:break
			await ticks()
		boarded = await jump_to(lift.global_position + Vector2(0, -16), 112, lift)
		if boarded:break
	check(boarded, "Board the moving counterweight from the stair landing")
	if boarded:
		for frame in 240:
			if lift.global_position.y < -5050:break
			await ticks()
		check(await jump_to(Vector2(-1152, -5184), 128), "Ride counterweight and jump onto the transfer perch")
	var relay: Node2D = world.get_node("Map/Platforms/Relay/ActualPlatform")
	var relay_boarded := false
	for attempt in 3:
		await spawn(Vector2(-1152, -5192))
		var previous_x := relay.global_position.x
		for frame in 240:
			var x := relay.global_position.x
			if x > -960 and x < -880 and x < previous_x:break
			previous_x = x
			await ticks()
		relay_boarded = await jump_to(relay.global_position + Vector2(0, -16), 112, relay, 12)
		if relay_boarded:break
	check(relay_boarded, "Transfer onto the live horizontal relay lift")
	if relay_boarded:
		for frame in 240:
			if relay.global_position.x > -780:break
			await ticks()
		check(await jump_to(Vector2(-608, -5504), 160, null, 10), "Leave relay at the far end to reach the next shrine")
	# Keep hazards live: retry the whole court from its boundary shrine, never
	# teleport between ledges or switch the hazards off to manufacture a pass.
	var court_ok := false
	for attempt in 6:
		await spawn(Vector2(-608, -5512))
		await ticks(attempt * 9)
		court_ok = true
		for at in [Vector2(-880, -5664), Vector2(-1168, -5792), Vector2(-880, -5952), Vector2(-1168, -6080), Vector2(-1104, -6240), Vector2(-1328, -6400)]:
			if not await jump_to(at, 96, null, 0):
				court_ok = false
				break
		if court_ok:break
	check(court_ok, "Needle court completed with moving blades active")

	# The old scaffold grid begins above the new chapter, with its original planks.
	await spawn(Vector2(-1328, -6408))
	check(await jump_to(Vector2(-1097, -6549), 154), "New chapter connects to the first original scaffold plank")
	check(await jump_to(Vector2(-1234, -6670), 154), "Original scaffold ascent continues beyond the connection")
