extends RefCounted

const SHEET = preload("res://Art/StoneSheet/stone_sheet.png")
const SHADER = preload("res://Art/StoneSheet/atlas_terrain.gdshader")
const STYLE_NAMES = ["Moss stone", "Ice stone"]
const SIDE_BITS = [TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_TOP_SIDE]
# Explicit source rectangles; the attachment is not a uniform export grid.
const REGIONS = [
	{"centre": Rect2(197, 198, 80, 80), "detail": Rect2(282, 198, 80, 80),
		"top_left": Rect2(25, 30, 80, 80), "top": Rect2(197, 30, 80, 80), "top_right": Rect2(367, 30, 80, 80),
		"left": Rect2(25, 198, 80, 80), "right": Rect2(367, 198, 80, 80),
		"bottom_left": Rect2(25, 282, 80, 80), "bottom": Rect2(282, 282, 80, 80), "bottom_right": Rect2(367, 282, 80, 80)},
	{"centre": Rect2(1132, 114, 80, 80), "detail": Rect2(1132, 114, 80, 80),
		"top_left": Rect2(787, 30, 80, 80), "top": Rect2(960, 30, 80, 80), "top_right": Rect2(1132, 30, 80, 80),
		"left": Rect2(960, 198, 80, 80), "right": Rect2(1216, 198, 80, 80),
		"bottom_left": Rect2(1132, 282, 80, 80), "bottom": Rect2(787, 282, 80, 80), "bottom_right": Rect2(1047, 282, 80, 80)}]
const SLOPES = [
	{14: Rect2(535, 30, 80, 80), 25: Rect2(451, 30, 80, 80), 36: Rect2(620, 198, 80, 80), 37: Rect2(535, 198, 80, 80)},
	{14: Rect2(1290, 30, 80, 80), 25: Rect2(1216, 30, 80, 80), 36: Rect2(1290, 198, 80, 80), 37: Rect2(1290, 198, 80, 80)}]
const SLOPE_POINTS = {14: [Vector2(-40, 40), Vector2(40, -40), Vector2(40, 40)],
	25: [Vector2(-40, -40), Vector2(-40, 40), Vector2(40, 40)],
	36: [Vector2(-40, -40), Vector2(40, -40), Vector2(40, 40)],
	37: [Vector2(-40, -40), Vector2(40, -40), Vector2(-40, 40)]}

static func vector(rect: Rect2) -> Vector4:
	return Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y)

static func quadrant(style: int, horizontal: bool, vertical: bool, right: bool, bottom: bool) -> Rect2:
	var regions: Dictionary = REGIONS[style]
	if horizontal and vertical:
		return regions[("bottom_" if bottom else "top_") + ("right" if right else "left")]
	if horizontal:
		return regions["right" if right else "left"]
	if vertical:
		return regions["bottom" if bottom else "top"]
	# Shared faces sample inside the tile's transparent/bordered perimeter.
	return regions["centre"].grow(-5)

static func material(style: int, connections: int, base: Rect2) -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = SHADER
	result.set_shader_parameter("sheet", SHEET)
	result.set_shader_parameter("base_region", vector(base))
	var right := (connections & 1) == 0
	var bottom := (connections & 2) == 0
	var left := (connections & 4) == 0
	var top := (connections & 8) == 0
	result.set_shader_parameter("top_left", vector(quadrant(style, left, top, false, false)))
	result.set_shader_parameter("top_right", vector(quadrant(style, right, top, true, false)))
	result.set_shader_parameter("bottom_left", vector(quadrant(style, left, bottom, false, true)))
	result.set_shader_parameter("bottom_right", vector(quadrant(style, right, bottom, true, true)))
	return result

static func source_at(rect: Rect2) -> TileSetAtlasSource:
	var source := TileSetAtlasSource.new()
	source.texture = SHEET
	source.margins = Vector2i(rect.position)
	source.texture_region_size = Vector2i(80, 80)
	source.use_texture_padding = false
	source.create_tile(Vector2i.ZERO)
	return source

static func square_collision(data: TileData) -> void:
	data.set_collision_polygons_count(0, 1)
	data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-40, -40), Vector2(40, -40), Vector2(40, 40), Vector2(-40, 40)]))

static func build() -> TileSet:
	var result := TileSet.new()
	result.tile_size = Vector2i(80, 80)
	result.set_meta("style_slope_alternatives", true)
	result.add_custom_data_layer()
	result.set_custom_data_layer_name(0, "asset_name")
	result.set_custom_data_layer_type(0, TYPE_STRING)
	result.add_physics_layer()
	result.set_physics_layer_collision_layer(0, 2)
	result.set_physics_layer_collision_mask(0, 5)
	for style in 2:
		result.add_terrain_set()
		result.set_terrain_set_mode(style, TileSet.TERRAIN_MODE_MATCH_SIDES)
		result.add_terrain(style)
		result.set_terrain_name(style, 0, STYLE_NAMES[style])
		result.set_terrain_color(style, 0, Color("63935e") if style == 0 else Color("98d9ff"))
		var centre: Rect2 = REGIONS[style]["centre"]
		var source := source_at(centre)
		source.resource_name = STYLE_NAMES[style]
		result.add_source(source, style)
		for connections in 16:
			var alternative := 0 if connections == 15 else source.create_alternative_tile(Vector2i.ZERO, connections + 1)
			var data := source.get_tile_data(Vector2i.ZERO, alternative)
			data.terrain_set = style
			data.terrain = 0
			data.material = material(style, connections, centre)
			for side in 4:
				data.set_terrain_peering_bit(SIDE_BITS[side], 0 if connections & (1 << side) else -1)
			square_collision(data)
		var detail := source.get_tile_data(Vector2i.ZERO, source.create_alternative_tile(Vector2i.ZERO, 16))
		detail.terrain_set = style
		detail.terrain = 0
		detail.probability = 0.25
		detail.material = material(style, 15, centre)
		for part in ["top_left", "top_right", "bottom_left", "bottom_right"]:
			detail.material.set_shader_parameter(part, vector(REGIONS[style]["detail"].grow(-5)))
		for side in SIDE_BITS:
			detail.set_terrain_peering_bit(side, 0)
		square_collision(detail)
	for number in SLOPE_POINTS:
		var base: Rect2 = SLOPES[0][number]
		var source := source_at(base)
		source.resource_name = "Manual slope %d" % number
		result.add_source(source, number)
		for style in 2:
			var alternative := 0 if style == 0 else source.create_alternative_tile(Vector2i.ZERO, 1)
			var data := source.get_tile_data(Vector2i.ZERO, alternative)
			data.material = material(style, 15, base)
			data.material.set_shader_parameter("direct_texture", true)
			data.material.set_shader_parameter("top_left", vector(SLOPES[style][number]))
			data.material.set_shader_parameter("art_flip_h", style == 1 and number == 36)
			data.set_collision_polygons_count(0, 1)
			data.set_collision_polygon_points(0, 0, PackedVector2Array(SLOPE_POINTS[number]))
	# Separate sources preserve irregular and overlapping image crops exactly.
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://Art/StoneSheet/catalog.json"))["entries"]
	for index in entries.size():
		var entry: Dictionary = entries[index]
		var rectangle: Array = entry["region"]
		var atlas := TileSetAtlasSource.new()
		atlas.resource_name = entry["name"]
		atlas.texture = SHEET
		atlas.margins = Vector2i(rectangle[0], rectangle[1])
		atlas.texture_region_size = Vector2i(rectangle[2], rectangle[3])
		atlas.use_texture_padding = false
		atlas.create_tile(Vector2i.ZERO)
		result.add_source(atlas, 100 + index)
		var data := atlas.get_tile_data(Vector2i.ZERO, 0)
		data.set_custom_data("asset_name", entry["name"])
		var name: String = entry["name"]
		for style in 2:
			var prefix := "moss_" if style == 0 else "ice_"
			if name.begins_with(prefix):
				var part := name.trim_prefix(prefix)
				if REGIONS[style].has(part):
					square_collision(data)
				var number: int = {"slope_up_right": 14, "slope_down_right": 25, "ceiling_right": 36, "ceiling_left": 37}.get(part, -1)
				if number >= 0:
					data.set_collision_polygons_count(0, 1)
					data.set_collision_polygon_points(0, 0, PackedVector2Array(SLOPE_POINTS[number]))
	return result
