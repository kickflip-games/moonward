extends Node

var checks := 0
var failures: Array[String] = []
var traces: Array = []
var world: Node2D
var player: Player

func _ready() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error("FAIL: " + label)

func ticks(n: int = 1) -> void:
	for i in n:
		await get_tree().physics_frame
		await get_tree().process_frame

func release() -> void:
	for action in ["ui_left", "ui_right", "jump"]:
		Input.action_release(action)

func run() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://World/Tower/room_manifest.json"))
	for cycle in 2:
		world = load("res://World/Tower/PrototypeWorld.tscn").instantiate()
		add_child(world)
		await ticks(6)
		CheckpointManager._on_scene_changed()
		player = world.get_node("Player")
		check(world.get_node("Map/Rooms").get_child_count() == 30, "All 30 room concepts load on cycle %d" % cycle)
		check(CheckpointManager.checkpoints.size() == manifest.checkpoints, "All 53 shrines register without stale references")
		world.get_node("Map/WinZone").monitoring = false
		for i in CheckpointManager.checkpoints.size():
			var checkpoint: Checkpoint = CheckpointManager.checkpoints[i]
			check(checkpoint.progression_index == i, "Shrine %d has explicit route order" % i)
			checkpoint.activate_for(player)
			player.respawn()
			await ticks(12)
			check(not player.is_dead and CheckpointManager.current_checkpoint_index == i and player.is_on_floor(), "Shrine %d respawns on safe solid ground" % i)
		if cycle == 0:
			await live_mechanisms()
			await geometry_routes()
			await mechanism_checks()
			var win = world.get_node("Map/WinZone")
			win.trigger_win(player)
			check(win.endgame_cam.priority == 10 and player._input_locked, "New summit keeps the win camera and reward")
		world.queue_free()
		await ticks(3)
		CheckpointManager._on_scene_changed()
	check(CheckpointManager.checkpoints.is_empty(), "Reference tower teardown clears every shrine")
	var report := {"checks": checks, "failures": failures, "traces": traces, "scope": "checkpoint safety and individual main-route jumps with mechanisms held neutral; separate live mechanism checks"}
	var output := "/tmp/moonward-reference-tests.json"
	var args := OS.get_cmdline_user_args()
	if args.has("--output"):
		output = args[args.find("--output") + 1]
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("REFERENCE TOWER RESULT: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func live_mechanisms() -> void:
	# Move the real player through real physics areas, including the safe tell.
	player.set_physics_process(false)
	var seen := {}
	for room in world.get_node("Map/Rooms").get_children():
		for trap in room.get_node("Mechanisms").get_children():
			if trap.get_script() != load("res://World/Tower/trap.gd") or seen.has(trap.kind):
				continue
			seen[trap.kind] = true
			trap.process_mode = Node.PROCESS_MODE_ALWAYS
			trap.set_physics_process(false)
			trap.phase = 0
			var tell := 1.0 if trap.kind == "crusher" else 0.8 if trap.kind == "flame" else 0.0
			if trap.kind in ["crusher", "flame", "dart"]:
				player.update_respawn_position(trap.get_parent().to_global(trap.home))
				player.respawn()
				trap.elapsed = tell + 0.2
				trap._physics_process(0)
				await ticks(3)
				player._grace_timer = 0
				await ticks(3)
				check(not player.is_dead, "%s warning contact is physically safe" % trap.kind)
				trap.elapsed = tell + trap.warning_time + 0.2
				trap._physics_process(0)
			else:
				trap.elapsed = 0
				trap._physics_process(0)
			player.update_respawn_position(trap.global_position)
			player.respawn()
			# respawned resets nearby traps, so sample the live phase afterward.
			trap.elapsed = tell + trap.warning_time + 0.2 if trap.kind in ["crusher", "flame", "dart"] else 0.0
			trap._physics_process(0)
			await ticks(3)
			player._grace_timer = 0
			trap.set_physics_process(true)
			await ticks(3)
			check(player.is_dead, "%s live collider kills on contact" % trap.kind)
			trap.reset_cycle()
			trap.set_physics_process(true)
	# A platform from the crossing must carry rather than slide out from under
	# the player. Use the actual platform velocity, not a manual displacement.
	var lift = world.get_node("Map/Rooms/Room03/Mechanisms/Lift02")
	lift.process_mode = Node.PROCESS_MODE_ALWAYS
	lift.stop_tween()
	lift.get_node("ActualPlatform").sync_to_physics = false
	lift.get_node("ActualPlatform").position = lift.move_to
	lift.get_node("ActualPlatform").force_update_transform()
	PhysicsServer2D.body_set_state(lift.get_node("ActualPlatform").get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, lift.get_node("ActualPlatform").global_transform)
	player.update_respawn_position(lift.get_node("ActualPlatform").global_position - Vector2(0, 40))
	player.respawn()
	player.set_physics_process(true)
	await ticks(10)
	var relative_x: float = player.global_position.x - lift.get_node("ActualPlatform").global_position.x
	var before_x := player.global_position.x
	lift.get_node("ActualPlatform").sync_to_physics = true
	lift.start_tween()
	await ticks(85)
	check(absf(player.global_position.x - before_x) > 16 and absf(player.global_position.x - lift.get_node("ActualPlatform").global_position.x - relative_x) < 8, "Reference crossing lift carries the player")
	# The real breakable platform drops and restores its actual collider.
	var fragile = world.get_node("Map/Rooms/Room05/Mechanisms/Fragile01")
	fragile.process_mode = Node.PROCESS_MODE_ALWAYS
	player.update_respawn_position(fragile.global_position - Vector2(0, 34))
	player.respawn()
	await ticks(105)
	check(fragile.is_broken and fragile.get_node("CollisionShape2D").disabled, "Cracked bridge platform collapses after standing on it")
	player.update_respawn_position(world.get_node("Map/Rooms/Room05/Route/Step00").global_position)
	player.respawn()
	await ticks(150)
	check(not fragile.is_broken and not fragile.get_node("CollisionShape2D").disabled, "Cracked bridge platform restores for another attempt")
	var wind = world.get_node("Map/Rooms/Room28/Mechanisms/Gust0")
	wind.process_mode = Node.PROCESS_MODE_ALWAYS
	var wind_start: Vector2 = wind.global_position + Vector2(-40, 0)
	var samples: Array[float] = []
	for enabled in [false,true]:
		release()
		wind.collision_mask = 1 if enabled else 0
		player.update_respawn_position(wind_start)
		player.respawn()
		await ticks(8)
		samples.append(player.global_position.x)
	check(samples[1] - samples[0] > 10, "Gale Pass wind physically pushes an airborne player")

func geometry_routes() -> void:
	# Isolate collision and controller feasibility from phase-dependent timing.
	for room in world.get_node("Map/Rooms").get_children():
		room.set_physics_process(false)
		room.get_node("Mechanisms").process_mode = Node.PROCESS_MODE_ALWAYS
		for mechanism in room.get_node("Mechanisms").get_children():
			mechanism.process_mode = Node.PROCESS_MODE_ALWAYS
			mechanism.set_physics_process(false)
			mechanism.set_process(false)
			if mechanism is Area2D:
				mechanism.collision_layer = 0
				mechanism.collision_mask = 0
			elif mechanism.has_node("ActualPlatform"):
				mechanism.stop_tween()
				var body: AnimatableBody2D = mechanism.get_node("ActualPlatform")
				body.sync_to_physics = false
				body.position = Vector2.ZERO
				body.force_update_transform()
				PhysicsServer2D.body_set_state(body.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, body.global_transform)
			elif mechanism.has_node("DetectionArea"):
				mechanism.get_node("Timer").stop()
				mechanism.get_node("CollisionShape2D").disabled = false
				mechanism.is_breaking = false
				mechanism.is_broken = false
				mechanism.get_node("DetectionArea").monitoring = false
			elif mechanism.has_node("Area2D"):
				mechanism.collision_layer = 0
				mechanism.get_node("Area2D").monitoring = false
		for marker in room.get_node("Route").get_children():
			check(marker.position.x >= 32 and marker.position.x <= 1248, "Room %02d route marker is inside tower walls" % room.room_id)
	await ticks(3)
	for room in world.get_node("Map/Rooms").get_children():
		var steps := room.get_node("Route").get_children()
		for i in steps.size() - 1:
			var result := await jump_between(steps[i].global_position, steps[i + 1].global_position, float(steps[i + 1].get_meta("width")))
			check(result.ok, "%02d %s jump %d → %d is reachable with the real controller" % [room.room_id, room.room_name, i, i + 1])
			if not result.ok:
				var surface: Node2D = room.get_node(steps[i + 1].get_meta("surface"))
				traces.append({"room": room.room_id, "edge": i, "from": steps[i].global_position, "to": steps[i + 1].global_position, "surface": surface.global_position, "trace": result.trace})
		if room.has_node("RecoveryRoute"):
			var recovery := room.get_node("RecoveryRoute").get_children()
			for i in recovery.size() - 1:
				var result := await jump_between(recovery[i].global_position, recovery[i + 1].global_position, float(recovery[i + 1].get_meta("width")), true)
				check(result.ok, "Room %02d lower recovery jump %d reconnects" % [room.room_id, i])
				if not result.ok:
					traces.append({"room": room.room_id, "recovery_edge": i, "from": recovery[i].global_position, "to": recovery[i + 1].global_position, "trace": result.trace})
		var index := room.get_index()
		if index < 29:
			var next_room := world.get_node("Map/Rooms").get_child(index + 1)
			var result := await jump_between(steps[-1].global_position, next_room.get_node("Route/Step00").global_position, 224)
			check(result.ok, "Room %02d joins the next room without a teleport" % room.room_id)
		release()
	print("Individual room jumps checked")

func jump_between(start: Vector2, target: Vector2, width: float, accept_rejoin: bool = false) -> Dictionary:
	var last_trace: Array = []
	for attempt in [[0.0, 85], [0.0, 10], [0.0, 3], [-32.0, 85], [32.0, 85]]:
		var offset: float = attempt[0]
		release()
		player.update_respawn_position(start + Vector2(offset, 0))
		player.respawn()
		await ticks(8)
		Input.action_press("jump")
		last_trace = []
		for frame in 85:
			if frame == attempt[1]:
				Input.action_release("jump")
			var dx := target.x - player.global_position.x - player.velocity.x * 0.045
			Input.action_release("ui_left")
			Input.action_release("ui_right")
			if absf(dx) > 8:
				Input.action_press("ui_right" if dx > 0 else "ui_left")
			await ticks()
			if frame % 8 == 0:
				last_trace.append([player.global_position.x, player.global_position.y, player.velocity.x, player.velocity.y])
			var landed := absf(player.global_position.y - target.y - 16) < 14
			# A recovery lane succeeds if a jump rejoins the higher main route
			# sooner; it need not force the player back onto a lower scaffold.
			if accept_rejoin:
				landed = player.global_position.y <= target.y + 30
			if frame > 6 and player.is_on_floor() and absf(player.global_position.x - target.x) < width / 2 - 8 and landed:
				release()
				return {"ok": true, "trace": []}
			if player.global_position.y > maxf(start.y, target.y) + 190:
				break
	return {"ok": false, "trace": last_trace}

func mechanism_checks() -> void:
	var kinds := {}
	for room in world.get_node("Map/Rooms").get_children():
		for mechanism in room.get_node("Mechanisms").get_children():
			if mechanism.get_script() == load("res://World/Tower/trap.gd"):
				kinds[mechanism.kind] = true
				if mechanism.kind in ["crusher", "dart", "flame"]:
					mechanism.phase = 0
					var tell := 1.0 if mechanism.kind == "crusher" else 0.8 if mechanism.kind == "flame" else 0.0
					mechanism.elapsed = tell + 0.2
					mechanism._physics_process(0)
					check(mechanism.warning and not mechanism.armed, "%s has a non-lethal warning" % mechanism.kind)
					mechanism.elapsed = tell + mechanism.warning_time + 0.2
					mechanism._physics_process(0)
					check(mechanism.armed, "%s activates after its warning" % mechanism.kind)
					mechanism.elapsed = mechanism.period - 0.1
					mechanism._physics_process(0)
					check(not mechanism.armed, "%s gives a safe rest interval" % mechanism.kind)
					mechanism.reset_cycle()
					check(not mechanism.armed, "%s resets safely for retries" % mechanism.kind)
				mechanism.collision_layer = 0
	check(kinds.size() == 6, "All six trap types are present")
