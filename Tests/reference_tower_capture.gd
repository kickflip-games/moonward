extends Node

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var output := "/tmp/moonward-room-captures"
	if args.has("--output"):
		output = args[args.find("--output") + 1]
	DirAccess.make_dir_recursive_absolute(output)
	var world: Node2D = load("res://World/Tower/PrototypeWorld.tscn").instantiate()
	add_child(world)
	var player: Player = world.get_node("Player")
	player.set_physics_process(false)
	player.collision_layer = 0
	player.get_node("HurtArea").monitoring = false
	world.get_node("Map/WinZone").monitoring = false
	world.get_node("Camera2D").enabled = false
	world.get_node("Camera2D/PhantomCameraHost").queue_free()
	world.get_node("PhantomCamera2D").queue_free()
	var camera := Camera2D.new()
	add_child(camera)
	camera.make_current()
	for i in 5:
		await get_tree().process_frame
	for room in world.get_node("Map/Rooms").get_children():
		player.global_position = room.get_node("Route/Step00").global_position
		player.reset_physics_interpolation()
		camera.global_position = room.global_position + Vector2(640, -room.rise / 2 + 80)
		camera.zoom = Vector2.ONE * minf(get_viewport().get_visible_rect().size.x / 1408, get_viewport().get_visible_rect().size.y / (room.rise + 160))
		camera.reset_physics_interpolation()
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(output.path_join("%02d.png" % room.room_id))
		print("CAPTURED: " + room.room_name)
	# Include a normal gameplay frame and the final moon view.
	var first: Node2D = world.get_node("Map/Rooms").get_child(0)
	player.global_position = first.get_node("Route/Step00").global_position
	camera.global_position = player.global_position + Vector2(360,-220)
	camera.zoom = Vector2.ONE * 0.85
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join("start.png"))
	var last: Node2D = world.get_node("Map/Rooms").get_child(29)
	var steps: Array[Node] = last.get_node("Route").get_children()
	player.global_position = steps[-1].global_position
	camera.global_position = world.get_node("Map/CameraManager/EndgameCamera").global_position
	camera.zoom = Vector2.ONE * .85
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join("summit.png"))
	get_tree().quit()
