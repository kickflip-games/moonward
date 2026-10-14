extends Node2D

var textures: Array[Texture2D] = []
var layers: Array[TileMapLayer] = []
var inventory := false
var inventory_page := 0
const PAGE_SIZE = 40
const TILESET = preload("res://Art/Cavern/cavern_tileset.tres")

func terrain_tileset() -> TileSet:
	return TILESET

func load_inventory() -> void:
	for i in range(1, 38):
		textures.append(load("res://Art/Cavern/Tiles/Tile-%02d.png" % i))

func inventory_caption(index: int) -> String:
	return "Tile-%02d" % (index + 1)

func panel_stride() -> float:
	return 1128.0 / terrain_tileset().get_terrain_sets_count()

func _ready() -> void:
	load_inventory()
	for style in terrain_tileset().get_terrain_sets_count():
		var layer := TileMapLayer.new()
		layer.tile_set = terrain_tileset()
		layer.collision_enabled = false
		layer.position = Vector2(16 + style * panel_stride(), 86)
		layer.scale = Vector2.ONE * 36.0 / Vector2(layer.tile_set.tile_size)
		add_child(layer)
		layers.append(layer)
	reset()
	queue_redraw()
	var args := OS.get_cmdline_user_args()
	if args.has("--inventory"):
		toggle_inventory()
	if args.has("--capture"):
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(args[args.find("--capture") + 1])
		get_tree().quit()

func reset() -> void:
	seed(7)
	for style in layers.size():
		var layer := layers[style]
		layer.clear()
		var cells: Array[Vector2i] = []
		for rectangle in [Rect2i(0, 11, 10, 3), Rect2i(1, 2, 7, 2), Rect2i(2, 6, 4, 1),
			Rect2i(0, 5, 1, 6), Rect2i(7, 5, 1, 6), Rect2i(9, 5, 1, 6),
			Rect2i(2, 8, 1, 3), Rect2i(3, 10, 2, 1), Rect2i(3, 0, 1, 1)]:
			for x in range(rectangle.position.x, rectangle.end.x):
				for y in range(rectangle.position.y, rectangle.end.y):
					cells.append(Vector2i(x, y))
		layer.set_cells_terrain_connect(cells, style, 0, false)
		var alternative: int = style if layer.tile_set.get_meta("style_slope_alternatives", false) else 0
		layer.set_cell(Vector2i(5, 10), 14, Vector2i.ZERO, alternative)
		layer.set_cell(Vector2i(6, 10), 25, Vector2i.ZERO, alternative)

func toggle_inventory() -> void:
	inventory = not inventory
	for layer in layers:
		layer.visible = not inventory
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I:
			toggle_inventory()
		elif event.keycode == KEY_R:
			reset()
		elif inventory and event.keycode in [KEY_LEFT, KEY_RIGHT]:
			inventory_page = posmod(inventory_page + (1 if event.keycode == KEY_RIGHT else -1), ceili(float(textures.size()) / PAGE_SIZE))
			queue_redraw()
	if inventory:
		return
	var paint: bool = event is InputEventMouseButton and event.pressed
	paint = paint or (event is InputEventMouseMotion and event.button_mask != 0)
	if not paint:
		return
	var mouse_position: Vector2 = event.position
	var erase: bool = event.button_index == MOUSE_BUTTON_RIGHT if event is InputEventMouseButton else (event.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0
	for style in layers.size():
		var layer := layers[style]
		var cell := layer.local_to_map(layer.get_global_transform_with_canvas().affine_inverse() * mouse_position)
		if Rect2i(0, 0, 10, 14).has_point(cell):
			layer.set_cells_terrain_connect([cell], style, -1 if erase else 0, false)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1152, 648), Color("1b202b"))
	if not inventory:
		draw_string(ThemeDB.fallback_font, Vector2(16, 26), "Native terrain autotiles — click/drag to paint, right-click to erase, R reset, I inventory", HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
		for style in layers.size():
			var origin := Vector2(16 + style * panel_stride(), 86)
			draw_string(ThemeDB.fallback_font, origin + Vector2(0, -18), terrain_tileset().get_terrain_name(style, 0), HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
			draw_rect(Rect2(origin, Vector2(360, 504)), Color("303947"))
			for x in 11:
				draw_line(origin + Vector2(x * 36, 0), origin + Vector2(x * 36, 504), Color("3d4756"))
			for y in 15:
				draw_line(origin + Vector2(0, y * 36), origin + Vector2(360, y * 36), Color("3d4756"))
		return
	draw_string(ThemeDB.fallback_font, Vector2(16, 26), "Tile inventory — page %d/%d | Left/Right to browse" % [inventory_page + 1, ceili(float(textures.size()) / PAGE_SIZE)], HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
	for i in range(inventory_page * PAGE_SIZE, mini((inventory_page + 1) * PAGE_SIZE, textures.size())):
		var slot := i % PAGE_SIZE
		var origin := Vector2(16 + (slot % 8) * 142, 42 + (slot / 8) * 120)
		draw_rect(Rect2(origin, Vector2(132, 114)), Color("303947"))
		var texture := textures[i]
		var size := texture.get_size() * minf(4.0, minf(120.0 / texture.get_width(), 96.0 / texture.get_height()))
		draw_texture_rect(texture, Rect2(origin + Vector2((132 - size.x) / 2, 0), size), false)
		draw_string(ThemeDB.fallback_font, origin + Vector2(8, 108), inventory_caption(i).left(20), HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
