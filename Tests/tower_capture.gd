extends Node

## Synchronous fixed-view captures; advance only after the previous image is saved.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

func run() -> void:
	var args = OS.get_cmdline_user_args()
	var output = args[args.find("--output") + 1]
	var world = load("res://World/World.tscn").instantiate()
	add_child(world)
	var player: Player = world.get_node("Player")
	player.set_physics_process(false)
	player.collision_layer = 0
	player.get_node("HurtArea").monitoring = false
	world.get_node("Map/WinZone").monitoring = false
	for turret in world.get_node("Map/Turrets").get_children():
		turret.set_process(false)
		turret.set_physics_process(false)
	world.get_node("Camera2D").enabled = false
	world.get_node("Camera2D/PhantomCameraHost").queue_free()
	world.get_node("PhantomCamera2D").queue_free()
	var camera := Camera2D.new()
	camera.process_mode = Node.PROCESS_MODE_ALWAYS
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	add_child(camera)
	camera.make_current()
	for i in 10:
		await get_tree().physics_frame
		await get_tree().process_frame
	world.get_node("GameHud/MobileInputs").hide()
	get_tree().paused = true
	var shots = [["08_tower_start", Vector2(-1120, 480), Vector2(-1269, 744)],
		["09_tower_moving_shaft", Vector2(-1790, -2720), Vector2(-1745, -2700)],
		["10_tower_moving_hazards", Vector2(-1060, -7820), Vector2(-1500, -7753)],
		["11_tower_turrets", Vector2(-1120, -7240), Vector2(-1300, -7180)]]
	if args.has("--art-details"):
		var platform_origin: Vector2 = world.get_node("Map/Platforms").global_position
		shots.append_array([
			["12_tower_platforms", platform_origin + Vector2(700, 380), platform_origin + Vector2(890, 545)],
			["13_tower_springboard", platform_origin + Vector2(1770, -5480), platform_origin + Vector2(1670, -5450)]])
	if args.has("--blackspire-review"):
		var rotor:Node2D=world.get_node("Map/Platforms/CirclePlatform")
		var fragile:Node2D=world.get_node("Map/Platforms/BreakablePlatform6")
		shots.append_array([
			["14_rotating_mechanism",rotor.global_position+Vector2(0,-90),rotor.global_position+Vector2(180,-110)],
			["15_breakable_section",fragile.global_position+Vector2(-70,-120),fragile.global_position+Vector2(0,-80)],
			["16_summit",Vector2(-1032,-10480),Vector2(-1032,-10042),Vector2(.71,.71)]])
	for shot in shots:
		camera.zoom=shot[3] if shot.size()>3 else Vector2.ONE
		camera.position = shot[1]
		player.position = shot[2]
		camera.reset_physics_interpolation()
		player.reset_physics_interpolation()
		HeightTracker.update_height()
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(output.path_join(shot[0] + ".png"))
		print("CAPTURED: " + shot[0])
	# Keep the frozen original tweens from advancing on teardown.
	world.queue_free()
	camera.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()
