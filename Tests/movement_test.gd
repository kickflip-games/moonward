extends Node2D

## Separate practice course. Number keys select a station; R retries it.
const STATIONS = [Vector2(0, -40), Vector2(1400, -40), Vector2(2300, -40),
	Vector2(3200, -40), Vector2(4200, -40), Vector2(5200, -120),
	Vector2(6100, -160), Vector2(7000, -40), Vector2(8200, -40)]
var player: Player
var camera: Camera2D
var phantom: PhantomCamera2D

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("171c29"))
	ground("Runway", Vector2(150, 40), Vector2(1100, 80))
	ground("GapLanding", Vector2(1030, -55), Vector2(180, 32))
	ground("WallFloor", Vector2(1500, 40), Vector2(650, 80))
	ground("SingleWall", Vector2(1540, -230), Vector2(40, 540))
	ground("AlternatingFloor", Vector2(2300, 40), Vector2(500, 80))
	ground("LeftWall", Vector2(2110, -480), Vector2(40, 1000))
	ground("RightWall", Vector2(2490, -480), Vector2(40, 1000))
	ground("ShaftFloor", Vector2(3200, 40), Vector2(250, 80))
	ground("ShaftLeft", Vector2(3120, -530), Vector2(32, 1100))
	ground("ShaftRight", Vector2(3280, -530), Vector2(32, 1100))
	ground("CeilingFloor", Vector2(4200, 40), Vector2(600, 80))
	ground("CeilingWall", Vector2(4360, -170), Vector2(32, 340))
	ground("LowCeiling", Vector2(4200, -180), Vector2(320, 32))
	var moving = load("res://Platforms/MovingPlatform.tscn").instantiate()
	moving.name = "MovingPlatform"
	moving.position = Vector2(5200, 0)
	moving.move_to = Vector2(140, 0)
	moving.speed = 120.0
	add_child(moving)
	ground("PlatformLanding", Vector2(5530, -30), Vector2(120, 32))
	ground("SpringFloor", Vector2(6100, 80), Vector2(650, 80))
	var spring = load("res://Platforms/bouncy/bouncy_platform.tscn").instantiate()
	spring.name = "Spring"
	spring.position = Vector2(6100, 0)
	add_child(spring)
	var angled = load("res://Platforms/bouncy/bouncy_platform.tscn").instantiate()
	angled.name = "AngledSpring"
	angled.position = Vector2(6350, 0)
	angled.rotation = PI / 6.0
	add_child(angled)
	ground("HazardFloor", Vector2(7200, 40), Vector2(700, 80))
	for data in [[Vector2(7170, -10), 0.0], [Vector2(7450, -210), PI]]:
		var spikes = load("res://Enemies/Spikes/spikes.tscn").instantiate()
		spikes.position = data[0]
		spikes.rotation = data[1]
		add_child(spikes)
	ground("TurretFloor", Vector2(8300, 40), Vector2(700, 80))
	player = load("res://Player/Player.tscn").instantiate()
	player.name = "Player"
	player.position = STATIONS[0]
	if "--baseline" in OS.get_cmdline_user_args():
		# Match the original main-tower instance, rather than its broken 9000 override.
		player.wall_jump_force = Vector2(1200, 1100)
	add_child(player)
	CheckpointManager.set_player(player)
	HeightTracker.set_player(player)
	var turret = load("res://Enemies/Turret/Turret.tscn").instantiate()
	turret.name = "Turret"
	turret.position = Vector2(8550, -160)
	turret.range = 650.0
	turret.projectile_speed = 400.0
	add_child(turret)
	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	add_child(camera)
	var host = PhantomCameraHost.new()
	camera.add_child(host)
	phantom = PhantomCamera2D.new()
	phantom.name = "PhantomCamera2D"
	phantom.follow_mode = PhantomCamera2D.FollowMode.SIMPLE
	phantom.follow_target = player
	phantom.follow_damping = true
	phantom.follow_damping_value = Vector2(0.09, 0.06)
	if "--baseline" in OS.get_cmdline_user_args():
		phantom.follow_mode = PhantomCamera2D.FollowMode.FRAMED
		phantom.dead_zone_width = 0.278
		phantom.dead_zone_height = 0.227
		phantom.follow_damping_value = Vector2(0.1, 0.1)
	add_child(phantom)
	if ResourceLoader.exists("res://World/CameraLookahead.gd"):
		var lookahead = Node.new()
		lookahead.set_script(load("res://World/CameraLookahead.gd"))
		phantom.add_child(lookahead)
	for i in STATIONS.size():
		var label = Label.new()
		label.position = STATIONS[i] + Vector2(-180, 110)
		label.text = "%d  %s" % [i + 1, ["Run / wide gap", "Single wall", "Alternating walls",
			"Narrow shaft", "Ceiling / wall coyote", "Moving platform", "Springboards",
			"Floor / ceiling spikes", "Turret warning"][i]]
		label.add_theme_font_size_override("font_size", 22)
		add_child(label)
	var ui = CanvasLayer.new()
	add_child(ui)
	var help = Label.new()
	help.position = Vector2(20, 20)
	help.text = "MOVEMENT PRACTICE   •   1–9: stations   •   R: retry   •   arrows/A/D + Space/C: move/jump"
	ui.add_child(help)

func ground(node_name: String, center: Vector2, size: Vector2) -> StaticBody2D:
	var body = StaticBody2D.new()
	body.name = node_name
	body.position = center
	body.collision_layer = 2
	body.collision_mask = 0
	var collider = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	var visual = Polygon2D.new()
	visual.polygon = PackedVector2Array([-size / 2, Vector2(size.x, -size.y) / 2,
		size / 2, Vector2(-size.x, size.y) / 2])
	visual.color = Color("60e5ca")
	body.add_child(visual)
	add_child(body)
	return body

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			player.update_respawn_position(STATIONS[event.keycode - KEY_1])
			player.respawn()
			phantom.teleport_position()
		elif event.keycode == KEY_R:
			player.respawn()
			phantom.teleport_position()

func _physics_process(_delta: float) -> void:
	if is_instance_valid(player) and player.position.y > 900:
		player.die()
