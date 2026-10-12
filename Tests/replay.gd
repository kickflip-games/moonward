extends Node

## Deterministic input replay and framebuffer capture. Run at --fixed-fps 60.
var stage: Node
var player: Player
var camera: Camera2D
var frame := 0
var output := ""
var rows: Array = []
var capture := false
var sample_name := ""
var deaths := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.max_fps = 60
	process_physics_priority = -100
	var args = OS.get_cmdline_user_args()
	output = args[args.find("--output") + 1] if "--output" in args else \
		"res://artifacts/gameplay_polish/after"
	capture = "--capture" in args
	DirAccess.make_dir_recursive_absolute(output)
	stage = load("res://Tests/MovementTest.tscn").instantiate()
	add_child(stage)
	player = stage.get_node("Player")
	camera = stage.get_node("Camera2D")
	player.died.connect(func(): deaths += 1)

func place(pos: Vector2) -> void:
	for action in ["ui_left", "ui_right", "jump"]:
		Input.action_release(action)
	player.update_respawn_position(pos)
	player.respawn()
	player._input_locked = false
	player.reset_physics_interpolation()
	stage.phantom.teleport_position()

func _physics_process(_delta: float) -> void:
	frame += 1
	match frame:
		90:
			place(Vector2(0, -16))
			sample_name = "01_jump"
			Input.action_press("ui_right")
		110: Input.action_press("jump")
		128: Input.action_release("jump")
		190: Input.action_release("ui_right")
		230:
			place(Vector2(2146, -160))
			sample_name = "02_alternating_walls"
			Input.action_press("ui_left")
		240: Input.action_press("jump")
		241: Input.action_release("jump")
		248:
			Input.action_release("ui_left")
			Input.action_press("ui_right")
		275: Input.action_press("jump")
		276: Input.action_release("jump")
		284:
			Input.action_release("ui_right")
			Input.action_press("ui_left")
		310: Input.action_press("jump")
		311: Input.action_release("jump")
		350:
			place(Vector2(3150, -180))
			sample_name = "03_narrow_shaft"
			Input.action_press("ui_left")
		360, 382, 404, 426, 448: Input.action_press("jump")
		361, 383, 405, 427, 449: Input.action_release("jump")
		368, 412, 456:
			Input.action_release("ui_left")
			Input.action_press("ui_right")
		390, 434:
			Input.action_release("ui_right")
			Input.action_press("ui_left")
		480:
			place(stage.get_node("MovingPlatform/ActualPlatform").global_position + Vector2(0, -30))
			sample_name = "04_moving_platform"
		550: Input.action_press("jump")
		565: Input.action_release("jump")
		600:
			place(Vector2(6100, -180))
			sample_name = "05_spring"
			Input.action_press("ui_right")
		645: Input.action_release("ui_right")
		730:
			place(Vector2(7000, -16))
			sample_name = "06_spikes_retry"
			Input.action_press("ui_right")
		750: Input.action_release("ui_right")
		850:
			place(Vector2(8200, -16))
			sample_name = "07_turret"
		1000:
			finish()
			return
	if frame >= 90:
		rows.append({"frame": frame, "section": sample_name, "x": player.position.x,
			"y": player.position.y, "vx": player.velocity.x, "vy": player.velocity.y,
			"floor": player.is_on_floor(), "wall_jump": player.is_wall_jumping,
			"locked": player._input_locked, "deaths": deaths,
			"camera_x": camera.global_position.x, "camera_y": camera.global_position.y})
	if capture and frame % 6 == 0 and frame >= 90:
		capture_frame.call_deferred("%s_%04d.png" % [sample_name, frame])

func capture_frame(filename: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join(filename))

func finish() -> void:
	set_physics_process(false)
	var file = FileAccess.open(output.path_join("replay.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(rows, "\t"))
	for node in stage.find_children("*", "Node2D", true, false):
		if node.has_method("stop_tween"):
			node.stop_tween()
	stage.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()
