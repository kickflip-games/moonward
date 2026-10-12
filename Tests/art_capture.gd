extends Node

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	var tileset: TileSet = load("res://Art/Dungeon/dungeon_tileset.tres")
	if tileset == null or tileset.get_source(0).get_tiles_count() != 45:
		push_error("Optional tileset failed to load all 45 regions")
		get_tree().quit(1)
		return
	print("ASSET CHECK: all 45 irregular atlas tiles load")
	var args = OS.get_cmdline_user_args()
	if "--validate-only" in args:
		get_tree().quit()
		return
	var output = args[args.find("--output") + 1]
	var preview = load("res://Art/Dungeon/Preview.tscn").instantiate()
	add_child(preview)
	var tabs: TabContainer = preview.find_children("*", "TabContainer", true, false)[0]
	for i in tabs.get_tab_count():
		tabs.current_tab = i
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(output.path_join("spritesheet_%d.png" % i))
	print("Captured five asset-preview tabs")
	get_tree().quit()
