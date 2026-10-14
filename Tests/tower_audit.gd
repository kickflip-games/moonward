extends Node

var failures := 0
var checks := 0

func _ready() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)
	else:
		print("PASS: " + label)

func ticks(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
		await get_tree().process_frame

func run() -> void:
	for cycle in 2:
		var world = load("res://World/LegacyWorld.tscn").instantiate()
		add_child(world)
		await ticks(5)
		CheckpointManager._on_scene_changed()
		check(CheckpointManager.checkpoints.size() == 10, "Tower registers ten checkpoints on load %d" % cycle)
		check(CheckpointManager.current_checkpoint_index == -1, "Fresh tower starts without an activated checkpoint")
		var player: Player = world.get_node("Player")
		var old_y := INF
		for i in 10:
			var checkpoint: Checkpoint = CheckpointManager.checkpoints[i]
			check(checkpoint.progression_index == i and checkpoint.global_position.y < old_y,
				"Checkpoint %d follows the ascending tower route" % i)
			old_y = checkpoint.global_position.y
			checkpoint.activate_for(player)
			player.respawn()
			await ticks(3)
			check(CheckpointManager.current_checkpoint_index == i and not player.is_dead,
				"Checkpoint %d activates and respawns safely" % i)
		check(world.get_node("Map/Spikes/MovingSpikes2/ActualPlatform/Hurtzone").get_child_count() == 5,
			"Composite moving spikes have five visual-matched collision polygons")
		player.update_respawn_position(Vector2(-1200, -7800))
		player.respawn()
		await ticks(2)
		check(is_equal_approx(world.get_node("PhantomCamera2D").zoom.x, 0.8),
			"The horizontal hazard room uses its wider camera frame after respawn")
		player.update_respawn_position(Vector2(-1200, 744))
		player.respawn()
		await ticks(2)
		check(is_equal_approx(world.get_node("PhantomCamera2D").zoom.x, 1.0),
			"Respawning outside the framing zone restores ordinary zoom")
		var win = world.get_node("Map/WinZone")
		win.auto_transition_delay = 0.0
		win.trigger_win(player)
		check(win.endgame_cam.priority == 10, "Original win camera and progression endpoint still work")
		world.queue_free()
		await ticks(3)
	CheckpointManager._on_scene_changed()
	check(CheckpointManager.checkpoints.is_empty(), "Tower teardown removes all checkpoint references")
	print("TOWER RESULT: %d checks, %d failures (checkpoint traversal, not an unassisted completion)" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
