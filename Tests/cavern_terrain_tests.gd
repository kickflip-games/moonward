extends Node

const TILESET = preload("res://Art/Cavern/cavern_tileset.tres")
const RENDERER = preload("res://Art/Cavern/tower_terrain.gd")
const DIRECTIONS = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
const SIDE_BITS = [TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_TOP_SIDE]
var checks := 0
var failures := 0

func _ready() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)

func correct_peers(layer: TileMapLayer) -> bool:
	for cell in layer.get_used_cells():
		var data := layer.get_cell_tile_data(cell)
		for side in 4:
			var occupied := layer.get_cell_source_id(cell + DIRECTIONS[side]) != -1
			if data.get_terrain_peering_bit(SIDE_BITS[side]) != (0 if occupied else -1):
				return false
	return true

func signature(layer: TileMapLayer) -> Dictionary:
	var result := {}
	for cell in layer.get_used_cells():
		result[cell] = [layer.get_cell_source_id(cell), layer.get_cell_atlas_coords(cell), layer.get_cell_alternative_tile(cell)]
	return result

func run() -> void:
	seed(7)
	var layer := TileMapLayer.new()
	layer.tile_set = TILESET
	layer.collision_enabled = false
	add_child(layer)
	for style in 3:
		for mask in 16:
			layer.clear()
			var cells: Array[Vector2i] = [Vector2i(3, 3)]
			for side in 4:
				if mask & (1 << side):
					cells.append(Vector2i(3, 3) + DIRECTIONS[side])
			layer.set_cells_terrain_connect(cells, style, 0, false)
			check(layer.get_used_cells().size() == cells.size(), "Style %d mask %d paints no extra cells" % [style, mask])
			check(correct_peers(layer), "Style %d mask %d connects all edges correctly" % [style, mask])
		layer.clear()
		var rectangle: Array[Vector2i] = []
		for x in 7:
			for y in 5:
				rectangle.append(Vector2i(x, y))
		layer.set_cells_terrain_connect(rectangle, style, 0, false)
		layer.set_cells_terrain_connect([Vector2i(3, 2)], style, -1, false)
		check(layer.get_cell_source_id(Vector2i(3, 2)) == -1 and layer.get_used_cells().size() == 34,
			"Erasing terrain leaves a real opening in style %d" % style)
		check(correct_peers(layer), "Erasing reconnects the four surrounding edges in style %d" % style)
	layer.queue_free()
	var preview = load("res://Art/Cavern/Preview.tscn").instantiate()
	add_child(preview)
	var click := InputEventMouseButton.new()
	click.position = Vector2(554, 392)
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	preview._unhandled_input(click)
	check(preview.layers[1].get_cell_source_id(Vector2i(4, 8)) == 1,
		"Preview clicks paint the intended style and cell")
	click.button_index = MOUSE_BUTTON_RIGHT
	preview._unhandled_input(click)
	check(preview.layers[1].get_cell_source_id(Vector2i(4, 8)) == -1,
		"Preview right-clicks erase the intended cell")
	preview.queue_free()
	await get_tree().process_frame
	var world = load("res://World/LegacyWorld.tscn").instantiate()
	add_child(world)
	await get_tree().process_frame
	var original: TileMapLayer = world.get_node("Map/GameLayer")
	var before := signature(original)
	var visuals: TileMapLayer = RENDERER.apply(original) # Legacy kit is no longer the active main style.
	check(not visuals.collision_enabled and not visuals.navigation_enabled, "Tower visual terrain adds no colliders or navigation")
	var same_centres := true
	var hazards_untouched := true
	var same_slopes := true
	for cell in original.get_used_cells():
		var atlas := original.get_cell_atlas_coords(cell)
		if atlas == Vector2i(1, 0):
			hazards_untouched = hazards_untouched and visuals.get_cell_source_id(cell) == -1
		elif original.get_cell_tile_data(cell).get_collision_polygons_count(0) > 0:
			same_centres = same_centres and visuals.get_cell_source_id(cell) >= 0 and original.to_global(original.map_to_local(cell)).distance_to(visuals.to_global(visuals.map_to_local(cell))) < 0.005
			if RENDERER.SLOPE_SOURCES.has(atlas):
				same_slopes = same_slopes and visuals.get_cell_source_id(cell) == RENDERER.SLOPE_SOURCES[atlas]
	check(same_centres, "Every solid tower cell keeps its world position and 32-pixel grid")
	check(same_slopes, "All four slope orientations use matching art")
	check(hazards_untouched, "Damage tiles retain the existing hazard art")
	RENDERER.apply(original, 2)
	check(signature(original) == before, "Changing terrain style preserves every original tile and hazard cell")
	var source: TileSetAtlasSource = TILESET.get_source(0)
	check(not source.get_tile_data(Vector2i.ZERO, 0).material.get_shader_parameter("preserve_outline"),
		"Tower styling does not mutate the reusable TileSet resource")
	world.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("CAVERN RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
