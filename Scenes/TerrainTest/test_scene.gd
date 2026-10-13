extends Node2D

@onready var player: Player = $Player
@onready var camera: Camera2D = $Camera2D
var capture_mode := false

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	capture_mode = args.has("--capture-dir")
	if capture_mode:
		capture.call_deferred(args[args.find("--capture-dir") + 1])
	else:
		camera.position = player.position + Vector2(120,-60)
		camera.zoom = Vector2.ONE * 1.25

func _process(delta: float) -> void:
	if capture_mode:
		return
	camera.position = camera.position.lerp(player.position + Vector2(100,-70), 1.0-exp(-8.0*delta))
	if player.position.y > 2200:
		player.respawn()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		player.respawn()
	if event is InputEventKey and event.pressed:
		var views := [Vector2(260,200),Vector2(350,620),Vector2(860,620),Vector2(800,1010)]
		if event.keycode >= KEY_1 and event.keycode <= KEY_4:
			camera.position = views[event.keycode-KEY_1]
			camera.zoom = Vector2.ONE * 1.5
			set_process(false)
		elif event.keycode == KEY_5:
			set_process(true)

func capture(output: String) -> void:
	# Let the original player finish spawning and settle on actual terrain.
	for frame in 60:
		await get_tree().physics_frame
	player.set_physics_process(false)
	var shots := [
		["00_previous_borders",Vector2(224,208),2.0,["PreviousWall"]],
		["01_large_wall",Vector2(224,208),2.0,["LargeMossWall"]],
		["02_irregular_hole",Vector2(350,596),1.5,["MossEnvironment"]],
		["03_moss_environment",Vector2(350,596),1.5,["MossEnvironment","MossDecorations"]],
		["04_snow_environment",Vector2(890,596),1.5,["SnowEnvironment","SnowDecorations"]],
		["05_slopes",Vector2(984,1060),1.0,["SlopeDemonstration"]],
		["06_mixed_materials",Vector2(1000,208),1.5,["MixedMaterials"]],
		["07_player_route",Vector2(350,1760),1.45,["GameplayRoute"]],
		["08_overview",Vector2(740,1000),0.35,[]],
	]
	for shot in shots:
		for child in get_children():
			if child is TileMapLayer:
				child.visible = child.name in shot[3] if not shot[3].is_empty() else child.name != "PreviousWall"
			elif child is Label:
				child.visible = shot[0] == "08_overview"
		player.visible = shot[0] == "07_player_route"
		camera.position = shot[1]
		camera.zoom = Vector2.ONE * shot[2]
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(output.path_join(shot[0]+".png"))
	get_tree().quit()
