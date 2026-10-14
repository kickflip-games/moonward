extends Node
const DIR="res://Art/BlackSpire/"
const SIDES=[TileSet.CELL_NEIGHBOR_RIGHT_SIDE,TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,TileSet.CELL_NEIGHBOR_LEFT_SIDE,TileSet.CELL_NEIGHBOR_TOP_SIDE]
func _ready() -> void:
	var meta: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DIR+"catalog.json"))
	var set:=TileSet.new()
	set.tile_size=Vector2i(24,24)
	set.add_custom_data_layer();set.set_custom_data_layer_name(0,"asset_name");set.set_custom_data_layer_type(0,TYPE_STRING)
	set.add_physics_layer();set.set_physics_layer_collision_layer(0,2);set.set_physics_layer_collision_mask(0,5)
	set.add_terrain_set();set.set_terrain_set_mode(0,TileSet.TERRAIN_MODE_MATCH_SIDES)
	set.add_terrain(0);set.set_terrain_name(0,0,"BlackSpire stone");set.set_terrain_color(0,0,Color("b65656"))
	var source:=TileSetAtlasSource.new()
	source.texture=load(DIR+"Terrain/terrain_atlas.png");source.texture_region_size=Vector2i(24,24)
	source.resource_name="Stone — side terrain / manual original slopes"
	source.resource_scene_unique_id="TerrainAtlas";source.texture.resource_scene_unique_id="TerrainImage"
	set.add_source(source,0)
	for tile in meta.terrain_tiles:
		var at:=Vector2i(tile.atlas_coords[0],tile.atlas_coords[1]);source.create_tile(at)
		var data:=source.get_tile_data(at,0);data.set_custom_data("asset_name",tile.name)
		var points:=PackedVector2Array()
		for p in tile.collision:points.append(Vector2(p[0],p[1]))
		data.set_collision_polygons_count(0,1);data.set_collision_polygon_points(0,0,points)
		if tile.get("one_way",false):data.set_collision_polygon_one_way(0,0,true)
		if tile.kind=="terrain":
			data.terrain_set=0;data.terrain=0
			for side in 4:data.set_terrain_peering_bit(SIDES[side],0 if int(tile.mask) & (1<<side) else -1)
	ResourceSaver.save(set,DIR+"Terrain/medieval_terrain.tres")
	var props:=TileSet.new();props.tile_size=Vector2i(24,24)
	props.add_custom_data_layer();props.set_custom_data_layer_name(0,"asset_name");props.set_custom_data_layer_type(0,TYPE_STRING)
	var prop_source:=TileSetAtlasSource.new();prop_source.texture=load(DIR+"Props/props_atlas.png");prop_source.texture_region_size=Vector2i(24,24)
	prop_source.resource_name="Architecture and props — no collision"
	prop_source.resource_scene_unique_id="PropsAtlas";prop_source.texture.resource_scene_unique_id="PropsImage"
	props.add_source(prop_source,0)
	for item in meta.props:
		var at:=Vector2i(item.atlas_coords[0],item.atlas_coords[1])
		prop_source.create_tile(at,Vector2i(item.size_in_atlas[0],item.size_in_atlas[1]))
		prop_source.get_tile_data(at,0).set_custom_data("asset_name",item.name)
	ResourceSaver.save(props,DIR+"Props/medieval_props.tres")
	var quiet:=TileSet.new();quiet.tile_size=Vector2i(16,16)
	var qs:=TileSetAtlasSource.new();qs.texture=load(DIR+"Terrain/quiet_geometry.png");qs.texture_region_size=Vector2i(16,16)
	qs.resource_scene_unique_id="QuietAtlas";qs.texture.resource_scene_unique_id="QuietImage"
	quiet.add_source(qs,0)
	for i in 5:qs.create_tile(Vector2i(i,0))
	ResourceSaver.save(quiet,DIR+"Terrain/quiet_geometry.tres")
	print("BLACKSPIRE BUILD: native terrain, props and collision-free tower visual resources saved")
	get_tree().quit()
