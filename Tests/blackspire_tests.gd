extends Node
const SET=preload("res://Art/BlackSpire/Terrain/medieval_terrain.tres")
const PROPS=preload("res://Art/BlackSpire/Props/medieval_props.tres")
const RENDERER=preload("res://Art/BlackSpire/tower_terrain.gd")
const SIDES=[TileSet.CELL_NEIGHBOR_RIGHT_SIDE,TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,TileSet.CELL_NEIGHBOR_LEFT_SIDE,TileSet.CELL_NEIGHBOR_TOP_SIDE]
const DIRECTIONS=[Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]
var checks:=0
var failures:Array[String]=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error("FAIL: "+label)
func tick(count:int=1)->void:
	for i in count:await get_tree().physics_frame;await get_tree().process_frame
func signature(layer:TileMapLayer)->String:
	var entries:Array=[]
	for cell in layer.get_used_cells():
		var data:=layer.get_cell_tile_data(cell)
		var poly:Array=[]
		for l in layer.tile_set.get_physics_layers_count():
			for j in data.get_collision_polygons_count(l):poly.append(data.get_collision_polygon_points(l,j))
		entries.append(str([cell,layer.get_cell_source_id(cell),layer.get_cell_atlas_coords(cell),layer.get_cell_alternative_tile(cell),poly]))
	entries.sort()
	return str(entries)
func manual_at(name:String,meta:Dictionary)->Vector2i:
	for tile in meta.terrain_tiles:
		if tile.name==name:return Vector2i(tile.atlas_coords[0],tile.atlas_coords[1])
	return Vector2i(-1,-1)
func walk_profile(player:Player,meta:Dictionary,gentle:bool,direction:int)->void:
	var track:=TileMapLayer.new();track.tile_set=SET;track.scale=Vector2.ONE*2
	track.position=Vector2(6000,0);add_child(track)
	var cells:Array[Vector2i]=[]
	for x in range(-4,12):
		for y in range(1,4):cells.append(Vector2i(x,y))
	track.set_cells_terrain_connect(cells,0,0,false)
	var sequence:Array
	if gentle:
		sequence=[[0,0,"up_gentle_low"],[1,0,"up_gentle_middle"],[2,0,"up_gentle_high"],
			[3,0,"sides_0f"],[4,0,"sides_0f"],[5,0,"down_gentle_high"],[6,0,"down_gentle_middle"],[7,0,"down_gentle_low"]]
	else:
		for x in range(1,5):track.set_cell(Vector2i(x,0),0,manual_at("sides_0f",meta))
		sequence=[[0,0,"up_45"],[1,-1,"up_45"],[2,-1,"sides_0f"],[3,-1,"sides_0f"],[4,-1,"down_45"],[5,0,"down_45"]]
	for part in sequence:track.set_cell(Vector2i(part[0],part[1]),0,manual_at(part[2],meta))
	await tick(3)
	var end:float=6456 if gentle else 6360
	player.update_respawn_position(Vector2(5900 if direction>0 else end,24));player.respawn();await tick(25)
	var minimum_y:float=player.position.y
	Input.action_press("ui_right" if direction>0 else "ui_left")
	for frame in 140:
		await tick();minimum_y=minf(minimum_y,player.position.y)
		if (direction>0 and player.position.x>=end) or (direction<0 and player.position.x<=5900):break
	Input.action_release("ui_right");Input.action_release("ui_left");await tick(20)
	var crossed:bool=player.position.x>=end if direction>0 else player.position.x<=5900
	# The unchanged body has its collision foot eight pixels below its origin.
	check(crossed and minimum_y<(-5 if gentle else -50) and player.is_on_floor() and abs(player.position.y-40)<2,
		"Actual player runs uphill/downhill and flat junctions: %s direction %d"%["1:3" if gentle else "45 degrees",direction])
	track.queue_free();await tick(3)
func _ready()->void:run.call_deferred()
func run()->void:
	var meta:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://Art/BlackSpire/catalog.json"))
	for name in meta.source_sha256:
		var context:=HashingContext.new();context.start(HashingContext.HASH_SHA256)
		context.update(FileAccess.get_file_as_bytes("res://Art/BlackSpire/Source/"+name))
		check(context.finish().hex_encode()==meta.source_sha256[name],"Original source preserved "+name)
	check(SET.tile_size==Vector2i(24,24),"Native logical grid follows 24px cap construction")
	check(SET.get_terrain_set_mode(0)==TileSet.TERRAIN_MODE_MATCH_SIDES,"Honest side matching coverage")
	check(PROPS.get_physics_layers_count()==0,"Decorations have no collision")
	var source:TileSetAtlasSource=SET.get_source(0)
	for tile in meta.terrain_tiles:
		var at:=Vector2i(tile.atlas_coords[0],tile.atlas_coords[1])
		var data:=source.get_tile_data(at,0)
		var valid:=true
		for point in data.get_collision_polygon_points(0,0):valid=valid and abs(point.x)<=12.01 and abs(point.y)<=12.01
		check(valid,"Collision bounds "+tile.name)
		check(source.get_tile_texture_region(at).size==Vector2i(24,24),"Atlas cell "+tile.name)
		if tile.kind=="slope":check(data.terrain_set==-1,"Manual slope avoids false native inference")
	var layer:=TileMapLayer.new();layer.tile_set=SET;layer.collision_enabled=false;add_child(layer)
	for mask in 16:
		layer.clear()
		var cells:Array[Vector2i]=[Vector2i.ZERO]
		for side in 4:
			if mask&(1<<side):cells.append(DIRECTIONS[side])
		layer.set_cells_terrain_connect(cells,0,0,false)
		var data:=layer.get_cell_tile_data(Vector2i.ZERO);var peers_ok:=data!=null
		for side in 4:peers_ok=peers_ok and data.get_terrain_peering_bit(SIDES[side])==(0 if mask&(1<<side) else -1)
		check(peers_ok and layer.get_used_cells().size()==cells.size(),"Native painting side mask %d"%mask)
	layer.queue_free();await tick(2)
	var world=load("res://World/World.tscn").instantiate();add_child(world);await tick(6)
	var geometry:TileMapLayer=world.get_node("Map/GameLayer");var before:=signature(geometry)
	var root:Node2D=world.get_node("Map/BlackSpireTerrain")
	var visual:TileMapLayer=root.get_node("QuietStructure")
	check(not visual.collision_enabled and visual.tile_set.get_physics_layers_count()==0,"Tower overlay adds zero collision")
	var alignment:=true;var expected:=0
	for cell in geometry.get_used_cells():
		var data:=geometry.get_cell_tile_data(cell)
		if data.get_collision_polygons_count(0)>0:
			expected+=1
			alignment=alignment and geometry.to_global(geometry.map_to_local(cell)).distance_to(visual.to_global(visual.map_to_local(cell)))<.01
	check(alignment and visual.get_used_cells().size()==expected,"Every main solid cell remains aligned")
	RENDERER.apply(geometry)
	check(signature(geometry)==before,"Style application preserves every original collision and hazard cell")
	check(world.get_node_or_null("Map/CavernTerrain")==null,"Old Gothic renderer is inactive")
	check(not world.get_node("WorldEnvironment").environment.glow_enabled,"Bloom disabled for crisp assets")
	var label:Label=world.get_node("GameHud/HeightUI/VBoxContainer/HeightLabel")
	check(label.get_global_rect().position.x>=0 and label.get_global_rect().position.y>=0,"HUD stays inside the screen")
	check(world.get_node("Map/Platforms/CirclePlatform/Sprite").get_child_count()==5,"Rotor has one visual replacement, no duplicate overlays")
	world.queue_free();await tick(3);CheckpointManager._on_scene_changed()
	var demo=load("res://Scenes/VisualDirectionTest.tscn").instantiate();add_child(demo);await tick(8)
	var player:Player=demo.get_node("Player")
	CheckpointManager._on_scene_changed()
	check(CheckpointManager.checkpoints.size()==3,"Test route has three deterministic checkpoints")
	player.update_respawn_position(Vector2(712,410));player.respawn();await tick(20)
	Input.action_press("ui_right");Input.action_press("jump")
	for frame in 35:
		await tick()
		if player.position.x>=832:break
	Input.action_release("ui_right");Input.action_press("ui_left");await tick(6)
	Input.action_release("ui_left");Input.action_release("jump");await tick(60)
	check(player.is_on_floor() and player.position.y<310 and player.position.x>768 and player.position.x<960,"Real player lands on the BlackSpire floating ledge")
	for side in [-1,1]:
		player.update_respawn_position(Vector2(1120 if side<0 else 1184,-100));player.respawn();await tick(5)
		Input.action_press("ui_left" if side<0 else "ui_right");await tick(6)
		Input.action_press("jump");await tick(2)
		check(player.is_wall_jumping and sign(player.velocity.x)==-side,"Actual wall jump in the new shaft %d"%side)
		for action in ["jump","ui_left","ui_right"]:Input.action_release(action)
	# Exercise all source gradients against actual raycast collision normals.
	var profile_ok:=true
	for tile in meta.terrain_tiles:
		if tile.kind!="slope":continue
		var slope:=TileMapLayer.new();slope.tile_set=SET;slope.position=Vector2(5000,5000);add_child(slope)
		slope.set_cell(Vector2i.ZERO,0,Vector2i(tile.atlas_coords[0],tile.atlas_coords[1]));await tick(2)
		for x in [4.0,12.0,20.0]:
			var y:float=tile.endpoints[0]+(tile.endpoints[1]-tile.endpoints[0])*x/24
			var hit:=get_viewport().world_2d.direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(5000+x,4950),Vector2(5000+x,5100),2))
			profile_ok=profile_ok and not hit.is_empty() and abs(hit.position.y-(5000+y))<.1
		slope.queue_free();await tick(2)
	check(profile_ok,"Original 45 degree and 1:3 grades match physical profiles")
	for gentle in [true,false]:
		for direction in [-1,1]:await walk_profile(player,meta,gentle,direction)
	demo.queue_free();await tick(60)
	print("BLACKSPIRE RESULT: %d checks, %d failures"%[checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
