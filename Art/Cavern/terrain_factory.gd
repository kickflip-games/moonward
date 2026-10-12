extends RefCounted

## Complete four-neighbour terrain rules. Existing pixel-art quarters supply
## thin ledges/columns where the pack has no dedicated combined-edge image.
const SHADER = preload("res://Art/Cavern/terrain_quarters.gdshader")
const SIDE_BITS = [TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_TOP_SIDE]
const STYLE_NAMES = ["Bare rock", "Green grass", "Purple grass"]
const TOP_TILES = [[1, 6, 2], [8, 10, 9], [29, 31, 30]]
const SLOPES = {14: [Vector2(-12, 12), Vector2(12, -12), Vector2(12, 12)],
	25: [Vector2(-12, -12), Vector2(-12, 12), Vector2(12, 12)],
	36: [Vector2(-12, -12), Vector2(12, -12), Vector2(12, 12)],
	37: [Vector2(-12, -12), Vector2(12, -12), Vector2(-12, 12)]}

static func texture(number: int) -> Texture2D:
	return load("res://Art/Cavern/Tiles/Tile-%02d.png" % number)

static func quadrant(style: int, horizontal_edge: bool, vertical_edge: bool, right: bool, bottom: bool) -> Texture2D:
	if vertical_edge and horizontal_edge:
		return texture((32 if right else 35) if bottom else TOP_TILES[style][2 if right else 0])
	if vertical_edge:
		return texture(33 if bottom else TOP_TILES[style][1])
	if horizontal_edge:
		return texture(5 if right else 4)
	return texture(3)

static func material(style: int, connections: int) -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = SHADER
	var right := (connections & 1) == 0
	var bottom := (connections & 2) == 0
	var left := (connections & 4) == 0
	var top := (connections & 8) == 0
	result.set_shader_parameter("top_left", quadrant(style, left, top, false, false))
	result.set_shader_parameter("top_right", quadrant(style, right, top, true, false))
	result.set_shader_parameter("bottom_left", quadrant(style, left, bottom, false, true))
	result.set_shader_parameter("bottom_right", quadrant(style, right, bottom, true, true))
	return result

static func build() -> TileSet:
	var result := TileSet.new()
	result.tile_size = Vector2i(24, 24)
	result.add_physics_layer()
	result.set_physics_layer_collision_layer(0, 2)
	result.set_physics_layer_collision_mask(0, 5)
	for style in 3:
		result.add_terrain_set()
		result.set_terrain_set_mode(style, TileSet.TERRAIN_MODE_MATCH_SIDES)
		result.add_terrain(style)
		result.set_terrain_name(style, 0, STYLE_NAMES[style])
		result.set_terrain_color(style, 0, [Color("716383"), Color("85ae45"), Color("8581c4")][style])
		var source := TileSetAtlasSource.new()
		source.resource_name = STYLE_NAMES[style]
		source.texture = texture(3)
		source.texture_region_size = Vector2i(24, 24)
		source.use_texture_padding = false
		source.create_tile(Vector2i.ZERO)
		result.add_source(source, style)
		for connections in 16:
			var alternative := 0 if connections == 15 else source.create_alternative_tile(Vector2i.ZERO, connections + 1)
			var data := source.get_tile_data(Vector2i.ZERO, alternative)
			data.terrain_set = style
			data.terrain = 0
			data.material = material(style, connections)
			for side in 4:
				data.set_terrain_peering_bit(SIDE_BITS[side], 0 if connections & (1 << side) else -1)
			data.set_collision_polygons_count(0, 1)
			data.set_collision_polygon_points(0, 0, PackedVector2Array([
				Vector2(-12, -12), Vector2(12, -12), Vector2(12, 12), Vector2(-12, 12)]))
		var variation := source.create_alternative_tile(Vector2i.ZERO, 16)
		var detail := source.get_tile_data(Vector2i.ZERO, variation)
		detail.terrain_set = style
		detail.terrain = 0
		detail.probability = 0.35
		detail.material = material(style, 15)
		for part in ["top_left", "top_right", "bottom_left", "bottom_right"]:
			detail.material.set_shader_parameter(part, texture(7))
		for side in SIDE_BITS:
			detail.set_terrain_peering_bit(side, 0)
		detail.set_collision_polygons_count(0, 1)
		detail.set_collision_polygon_points(0, 0, PackedVector2Array([
			Vector2(-12, -12), Vector2(12, -12), Vector2(12, 12), Vector2(-12, 12)]))
	for number in SLOPES:
		var source := TileSetAtlasSource.new()
		source.resource_name = "Manual slope %d" % number
		source.texture = texture(number)
		source.texture_region_size = Vector2i(24, 24)
		source.use_texture_padding = false
		source.create_tile(Vector2i.ZERO)
		result.add_source(source, number)
		var data := source.get_tile_data(Vector2i.ZERO, 0)
		data.set_collision_polygons_count(0, 1)
		data.set_collision_polygon_points(0, 0, PackedVector2Array(SLOPES[number]))
	return result
