extends RefCounted

## Decorative replacement: the original GameLayer remains the only collider
## and retains its cell data, damage layer and world-space outlines.
const TILESET = preload("res://Art/Cavern/cavern_tileset.tres")
const SHADER = preload("res://Art/Cavern/terrain_quarters.gdshader")
const OUTLINE = preload("res://Art/TilesetOf5.png")
const SLOPE_SOURCES = {Vector2i(0, 0): 14, Vector2i(2, 0): 25,
	Vector2i(0, 2): 36, Vector2i(2, 2): 37}
const FACES = {Vector2i(1, 1): 15, Vector2i(0, 0): 3, Vector2i(2, 0): 6,
	Vector2i(0, 2): 9, Vector2i(2, 2): 12}
const DIRECTIONS = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
const OPPOSITE = [4, 8, 1, 2]

static func configure_outline(material: ShaderMaterial, atlas: Vector2i) -> void:
	material.set_shader_parameter("outline", OUTLINE)
	material.set_shader_parameter("outline_region", Vector4(atlas.x / 3.0, atlas.y / 3.0, 1.0 / 3.0, 1.0 / 3.0))
	material.set_shader_parameter("preserve_outline", true)

static func apply(original: TileMapLayer, style: int = 1, brightness: float = 1.2) -> TileMapLayer:
	var parent := original.get_parent()
	var previous := parent.get_node_or_null("CavernTerrain")
	if previous:
		parent.remove_child(previous)
		previous.queue_free()
	var layer := TileMapLayer.new()
	layer.name = "CavernTerrain"
	layer.tile_set = TILESET.duplicate(true)
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.collision_enabled = false
	layer.navigation_enabled = false
	layer.z_index = original.z_index - 1
	layer.position = original.position
	layer.rotation = original.rotation
	layer.scale = original.scale * Vector2(original.tile_set.tile_size) / Vector2(layer.tile_set.tile_size)
	layer.modulate = Color(brightness, brightness, brightness, 1)
	parent.add_child(layer)
	for source_index in layer.tile_set.get_source_count():
		var source_id := layer.tile_set.get_source_id(source_index)
		var source: TileSetAtlasSource = layer.tile_set.get_source(source_id)
		for alternative_index in source.get_alternative_tiles_count(Vector2i.ZERO):
			var alternative := source.get_alternative_tile_id(Vector2i.ZERO, alternative_index)
			var data := source.get_tile_data(Vector2i.ZERO, alternative)
			var material: ShaderMaterial = data.material
			var atlas := Vector2i(1, 1)
			if source_id >= 3:
				material = ShaderMaterial.new()
				material.shader = SHADER
				material.set_shader_parameter("direct_texture", true)
				data.material = material
				for candidate in SLOPE_SOURCES:
					if SLOPE_SOURCES[candidate] == source_id:
						atlas = candidate
			configure_outline(material, atlas)
	var occupied: Dictionary = {}
	var solid_cells: Array[Vector2i] = []
	for cell in original.get_used_cells():
		var atlas := original.get_cell_atlas_coords(cell)
		if FACES.has(atlas):
			occupied[cell] = atlas
			solid_cells.append(cell)
	layer.set_cells_terrain_connect(solid_cells, style, 0, false)
	for cell in solid_cells:
		var atlas: Vector2i = occupied[cell]
		if SLOPE_SOURCES.has(atlas):
			layer.set_cell(cell, SLOPE_SOURCES[atlas], Vector2i.ZERO)
			continue
		var connections := 0
		for side in 4:
			var neighbour: Vector2i = occupied.get(cell + DIRECTIONS[side], Vector2i(-1, -1))
			if FACES.get(neighbour, 0) & OPPOSITE[side]:
				connections |= 1 << side
		var alternative := connections + 1 if connections != 15 else (16 if posmod(cell.x * 17 + cell.y * 31, 5) == 0 else 0)
		layer.set_cell(cell, style, Vector2i.ZERO, alternative)
	return layer
