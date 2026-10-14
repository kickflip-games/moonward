extends "res://Tests/cavern_terrain_tests.gd"

const STONE_TILESET = preload("res://Art/StoneSheet/stone_tileset.tres")
const SHEET = preload("res://Art/StoneSheet/stone_sheet.png")

func run() -> void:
	var picture := SHEET.get_image()
	check(picture.get_format() == Image.FORMAT_RGBA8 and picture.get_pixel(10, 10).a == 0,
		"The supplied source has real transparency")
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://Art/StoneSheet/catalog.json"))["entries"]
	check(STONE_TILESET.get_source_count() == entries.size() + 6, "The image atlas exposes every catalogue region as a native tile")
	for index in entries.size():
		var entry: Dictionary = entries[index]
		var raw_atlas: TileSetAtlasSource = STONE_TILESET.get_source(100 + index)
		var atlas: AtlasTexture = load(entry["texture"])
		check(Rect2(Vector2.ZERO, SHEET.get_size()).encloses(atlas.region) and atlas.region.size.x > 0 and atlas.region.size.y > 0,
			"Atlas region fits the sheet: " + entry["name"])
		check(raw_atlas.get_tile_texture_region(Vector2i.ZERO) == Rect2i(atlas.region),
			"Native atlas crops the correct image region: " + entry["name"])
	var layer := TileMapLayer.new()
	layer.tile_set = STONE_TILESET
	layer.collision_enabled = false
	add_child(layer)
	for style in 2:
		for mask in 16:
			layer.clear()
			var cells: Array[Vector2i] = [Vector2i(3, 3)]
			for side in 4:
				if mask & (1 << side):
					cells.append(Vector2i(3, 3) + DIRECTIONS[side])
			layer.set_cells_terrain_connect(cells, style, 0, false)
			check(layer.get_used_cells().size() == cells.size() and correct_peers(layer),
				"Stone style %d joins mask %d without extra cells" % [style, mask])
	layer.queue_free()
	var preview = load("res://Art/StoneSheet/Preview.tscn").instantiate()
	add_child(preview)
	var click := InputEventMouseButton.new()
	click.position = Vector2(580 + 4 * 36 + 18, 86 + 8 * 36 + 18)
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	preview._unhandled_input(click)
	check(preview.layers[1].get_cell_source_id(Vector2i(4, 8)) == 1, "Ice preview painting selects the correct cell")
	click.button_index = MOUSE_BUTTON_RIGHT
	preview._unhandled_input(click)
	check(preview.layers[1].get_cell_source_id(Vector2i(4, 8)) == -1, "Ice preview erasing updates the correct cell")
	preview.queue_free()
	await get_tree().process_frame
	var world = load("res://World/LegacyWorld.tscn").instantiate()
	add_child(world)
	await get_tree().process_frame
	var original: TileMapLayer = world.get_node("Map/GameLayer")
	var before := signature(original)
	for style in 2:
		var visual := RENDERER.apply(original, style, 1, STONE_TILESET)
		var aligned := not visual.collision_enabled and not visual.navigation_enabled
		var slopes_match := true
		for cell in original.get_used_cells():
			var atlas := original.get_cell_atlas_coords(cell)
			if original.get_cell_tile_data(cell).get_collision_polygons_count(0) > 0:
				aligned = aligned and visual.get_cell_source_id(cell) >= 0 and original.to_global(original.map_to_local(cell)).distance_to(visual.to_global(visual.map_to_local(cell))) < 0.005
			if RENDERER.SLOPE_SOURCES.has(atlas):
				slopes_match = slopes_match and visual.get_cell_source_id(cell) == RENDERER.SLOPE_SOURCES[atlas] and visual.get_cell_alternative_tile(cell) == style
			if atlas == Vector2i(1, 0):
				aligned = aligned and visual.get_cell_source_id(cell) == -1
		check(aligned, "Stone style %d aligns to the original grid without new collision or changed hazards" % style)
		check(slopes_match, "Stone style %d preserves all four slope orientations" % style)
		check(signature(original) == before, "Style switching keeps original tower cells")
	var source: TileSetAtlasSource = STONE_TILESET.get_source(0)
	check(not source.get_tile_data(Vector2i.ZERO, 0).material.get_shader_parameter("preserve_outline"), "Tower rendering preserves the reusable atlas resource")
	world.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("STONE RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
