extends Node
func _ready() -> void:run.call_deferred()
func run() -> void:
	var output := "res://artifacts/integrated_tower/output"
	var world = load("res://World/World.tscn").instantiate()
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
	for i in 5:await get_tree().process_frame
	for shot in [["entrance", Vector2(-1120, 480), Vector2(-1269, 744)],
		["collapsing_stair", Vector2(-1340, -4490), Vector2(-1216, -4296)],
		["relay_lifts", Vector2(-1120, -5140), Vector2(-1152, -5192)],
		["needle_court", Vector2(-1110, -5920), Vector2(-1168, -5800)],
		["scaffold_connection", Vector2(-1216, -6480), Vector2(-1328, -6408)],
		["original_scaffolds", Vector2(-1060, -7070), Vector2(-1097, -7100)],
		["original_hazards", Vector2(-1060, -10124), Vector2(-1697, -10057)],
		["summit", Vector2(-1032, -12784), Vector2(-1032, -12346)]]:
		camera.position = shot[1]
		camera.zoom = Vector2.ONE * .85
		player.position = shot[2]
		player.reset_physics_interpolation()
		camera.reset_physics_interpolation()
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(output.path_join(shot[0] + ".png"))
	get_tree().quit()
