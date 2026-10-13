extends Node

const DIRECTORY = "res://Art/Dungeon/Terrain/"
const PEERS = [TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER]

func canonical(mask: int) -> int:
	for group in [[1, 0, 2], [3, 2, 4], [5, 4, 6], [7, 6, 0]]:
		if not (mask & (1 << group[1]) and mask & (1 << group[2])):
			mask &= ~(1 << group[0])
	return mask

func set_terrain(data: TileData, style: int, mask: int) -> void:
	data.terrain_set = style
	data.terrain = 0
	data.set_custom_data("asset_name", "mask_%02x" % mask)
	for bit in 8:
		data.set_terrain_peering_bit(PEERS[bit], 0 if mask & (1 << bit) else -1)

func set_polygon(data: TileData, points: Array) -> void:
	var polygon := PackedVector2Array()
	for point in points:
		polygon.append(Vector2(point[0], point[1]))
	data.set_collision_polygons_count(0, 1)
	data.set_collision_polygon_points(0, 0, polygon)

func _ready() -> void:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY + "terrain_atlas.json"))
	var terrain := TileSet.new()
	terrain.tile_size = Vector2i(meta.tile_size, meta.tile_size)
	terrain.add_custom_data_layer()
	terrain.set_custom_data_layer_name(0, "asset_name")
	terrain.set_custom_data_layer_type(0, TYPE_STRING)
	terrain.add_physics_layer()
	terrain.set_physics_layer_collision_layer(0, 2)
	terrain.set_physics_layer_collision_mask(0, 5)
	var half: float = meta.tile_size / 2.0
	var square: Array = [[-half,-half],[half,-half],[half,half],[-half,half]]
	for style in meta.styles:
		var id: int = style.source_id
		terrain.add_terrain_set()
		terrain.set_terrain_set_mode(id, TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES)
		terrain.add_terrain(id)
		terrain.set_terrain_name(id, 0, "Moss Stone" if id == 0 else "Ice Stone")
		terrain.set_terrain_color(id, 0, Color("66995c") if id == 0 else Color("abdfff"))
		var source := TileSetAtlasSource.new()
		source.resource_name = "Moss — connected walls and manual slopes" if id == 0 else "Ice — connected walls and manual slopes"
		source.texture = load(DIRECTORY + style.name + "_terrain.png")
		source.resource_scene_unique_id = "MossAtlas" if id == 0 else "IceAtlas"
		source.texture.resource_scene_unique_id = "MossImage" if id == 0 else "IceImage"
		source.texture_region_size = terrain.tile_size
		terrain.add_source(source, id)
		for tile in style.tiles:
			var coords := Vector2i(tile.atlas_coords[0], tile.atlas_coords[1])
			source.create_tile(coords, Vector2i(1,2))
			var data := source.get_tile_data(coords, 0)
			data.set_custom_data("asset_name", tile.name)
			if tile.kind in ["slope", "manual_transition"]:
				set_polygon(data, tile.collision)
			else:
				set_polygon(data, square)
				set_terrain(data, id, tile.mask)
				if tile.kind == "interior_variant":
					data.probability = 0.6
				elif tile.mask == 255:
					data.probability = 0.4
				# Diagonal-only neighbours don't alter the silhouette. Their legal
				# eight-neighbour patterns share the same canonical visual tile.
				if tile.kind == "terrain":
					for mask in 256:
						if mask != tile.mask and canonical(mask) == tile.mask:
							var alt := source.create_alternative_tile(coords, mask+1)
							var alternative := source.get_tile_data(coords, alt)
							set_polygon(alternative, square)
							set_terrain(alternative, id, mask)
	var error := ResourceSaver.save(terrain, DIRECTORY + "gothic_terrain.tres")
	if error != OK:
		push_error(error_string(error))
		get_tree().quit(1)
		return
	var decorations := TileSet.new()
	decorations.tile_size = terrain.tile_size
	decorations.add_custom_data_layer()
	decorations.set_custom_data_layer_name(0, "asset_name")
	decorations.set_custom_data_layer_type(0, TYPE_STRING)
	var source := TileSetAtlasSource.new()
	source.resource_name = "Gothic props and surface overhangs — no collision"
	source.texture = load(DIRECTORY + "terrain_overlays.png")
	source.resource_scene_unique_id = "DecorAtlas"
	source.texture.resource_scene_unique_id = "DecorImage"
	source.texture_region_size = terrain.tile_size
	decorations.add_source(source, 0)
	for tile in meta.decorations:
		var coords := Vector2i(tile.atlas_coords[0],tile.atlas_coords[1])
		source.create_tile(coords, Vector2i(tile.size_in_atlas[0],tile.size_in_atlas[1]))
		source.get_tile_data(coords,0).set_custom_data("asset_name",tile.name)
	error = ResourceSaver.save(decorations,DIRECTORY+"decorations.tres")
	print("GOTHIC BUILD: native terrain and decoration resources saved")
	get_tree().quit(0 if error == OK else 1)
