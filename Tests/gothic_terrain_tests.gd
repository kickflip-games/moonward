extends Node

const TILESET = preload("res://Art/Dungeon/Terrain/gothic_terrain.tres")
const DECOR = preload("res://Art/Dungeon/Terrain/decorations.tres")
const BUILDER = preload("res://Art/Dungeon/Terrain/build_resources.gd")
const DIRECTIONS = [Vector2i(0,-1),Vector2i(1,-1),Vector2i(1,0),Vector2i(1,1),
	Vector2i(0,1),Vector2i(-1,1),Vector2i(-1,0),Vector2i(-1,-1)]
var failures: Array[String] = []
var checks := 0
var world: Node2D
var player: Player
var metadata: Dictionary

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("FAIL: " + message)

func canonical(mask: int) -> int:
	for group in [[1,0,2],[3,2,4],[5,4,6],[7,6,0]]:
		if not (mask & (1<<group[1]) and mask & (1<<group[2])):
			mask &= ~(1<<group[0])
	return mask

func signature(layer: TileMapLayer, cell: Vector2i) -> int:
	var data := layer.get_cell_tile_data(cell)
	var mask := 0
	if data:
		for bit in 8:
			if data.get_terrain_peering_bit(BUILDER.PEERS[bit]) == 0:
				mask |= 1<<bit
	return canonical(mask)

func neighbors(layer: TileMapLayer, cell: Vector2i) -> int:
	var mask := 0
	for bit in 8:
		if layer.get_cell_source_id(cell + DIRECTIONS[bit]) >= 0:
			mask |= 1<<bit
	return canonical(mask)

func tick(count: int = 1) -> void:
	for i in count:
		await get_tree().physics_frame
		await get_tree().process_frame

func place(pos: Vector2) -> void:
	for action in ["jump","ui_left","ui_right","ui_down"]:
		Input.action_release(action)
	player.update_respawn_position(pos)
	player.respawn()
	await tick(5)

func _ready() -> void:
	process_physics_priority = -100
	run.call_deferred()

func run() -> void:
	metadata = JSON.parse_string(FileAccess.get_file_as_string("res://Art/Dungeon/Terrain/terrain_atlas.json"))
	check(TILESET.tile_size == Vector2i(72,72),"Logical tile size")
	check(TILESET.get_terrain_sets_count()==2,"Separate material terrain sets")
	check(DECOR.get_physics_layers_count()==0 and DECOR.get_terrain_sets_count()==0,"Decorations cannot affect terrain or collision")
	for style in 2:
		var source: TileSetAtlasSource = TILESET.get_source(style)
		check(source.texture_region_size==Vector2i(72,72),"Fixed atlas units")
		check(TILESET.get_terrain_set_mode(style)==TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES,"Native corner and side matching")
		for tile in metadata.styles[style].tiles:
			var coords:=Vector2i(tile.atlas_coords[0],tile.atlas_coords[1])
			check(source.get_tile_texture_region(coords).size==Vector2i(72,144),"Padded native tile bounds "+tile.name)
			for alt_index in source.get_alternative_tiles_count(coords):
				var alt:=source.get_alternative_tile_id(coords,alt_index)
				var data:=source.get_tile_data(coords,alt)
				var poly:=data.get_collision_polygon_points(0,0)
				var valid: bool = poly.size()>=3 and not Geometry2D.offset_polygon(poly,0.01).is_empty()
				for point in poly:
					valid=valid and abs(point.x)<=36.001 and abs(point.y)<=36.001
				check(valid,"Collision stays in solid cell "+tile.name)
				check(data.material==null,"Native bitmap tile needs no runtime shader")
			if style==0:
				var ice_source: TileSetAtlasSource=TILESET.get_source(1)
				check(source.get_tile_data(coords,0).get_collision_polygon_points(0,0)==ice_source.get_tile_data(coords,0).get_collision_polygon_points(0,0),"Snow does not change solid geometry "+tile.name)
		var layer:=TileMapLayer.new()
		layer.tile_set=TILESET
		layer.collision_enabled=false
		add_child(layer)
		# Every possible 3x3 occupancy, including diagonal-only contacts.
		var mismatches: Array = []
		for mask in 256:
			layer.clear()
			var cells: Array[Vector2i] = [Vector2i.ZERO]
			for bit in 8:
				if mask & (1<<bit):cells.append(DIRECTIONS[bit])
			layer.set_cells_terrain_connect(cells,style,0,false)
			check(layer.get_used_cells().size()==cells.size(),"Painting preserves occupancy %d/%d"%[style,mask])
			if signature(layer,Vector2i.ZERO)!=canonical(mask):
				mismatches.append([mask,signature(layer,Vector2i.ZERO)])
		check(mismatches.is_empty(),"Neighbor masks match painted shape %d: %s"%[style,str(mismatches.slice(0,8))])
		layer.clear()
		var square: Array[Vector2i] = []
		for x in 8:
			for y in 6:square.append(Vector2i(x,y))
		layer.set_cells_terrain_connect(square,style,0,false)
		layer.set_cells_terrain_connect([Vector2i(3,3)],style,-1,false)
		check(layer.get_cell_source_id(Vector2i(3,3))==-1 and layer.get_used_cells().size()==47,"Native terrain erasing creates a hole")
		var corners:=true
		for cell in layer.get_used_cells():
			corners=corners and signature(layer,cell)==neighbors(layer,cell)
		check(corners,"Hole updates all inner and outer corners")
		layer.queue_free()
	await tick(2)
	world=load("res://Scenes/TerrainTest/GothicTerrainTest.tscn").instantiate()
	add_child(world)
	world.set_process(false)
	player=world.get_node("Player")
	await tick(60)
	var route: TileMapLayer=world.get_node("GameplayRoute")
	var mixed: TileMapLayer=world.get_node("MixedMaterials")
	check(mixed.get_cell_source_id(Vector2i(2,2))==0 and mixed.get_cell_source_id(Vector2i(7,2))==1,"Mixed boundary preserves material identity")
	var ray_ok:=true
	# Rays pass through decorative grass/snow and hit the exact solid profiles.
	for tile in metadata.styles[0].tiles:
		if tile.kind!="slope":continue
		var coords:=Vector2i(tile.atlas_coords[0],tile.atlas_coords[1])
		var layer:=TileMapLayer.new()
		layer.tile_set=TILESET
		layer.position=Vector2(5000,5000)
		add_child(layer)
		layer.set_cell(Vector2i.ZERO,0,coords)
		await tick(2)
		for x in [12.0,36.0,60.0]:
			var expected: float=tile.endpoints[0]+(tile.endpoints[1]-tile.endpoints[0])*x/72.0
			var from:=Vector2(5000+x,4900)
			var to:=Vector2(5000+x,5200)
			if tile.name.begins_with("ceiling"):
				from=Vector2(5000+x,5200)
				to=Vector2(5000+x,4900)
			var query:=PhysicsRayQueryParameters2D.create(from,to,2)
			var hit:=get_viewport().world_2d.direct_space_state.intersect_ray(query)
			var gradient: float=(tile.endpoints[1]-tile.endpoints[0])/72.0
			var normal:=Vector2(gradient,-1).normalized()
			if tile.name.begins_with("ceiling"):normal=-normal
			ray_ok=ray_ok and not hit.is_empty() and abs(hit.position.y-(5000+expected))<0.1 and hit.normal.dot(normal)>0.999
		layer.queue_free()
		await tick(2)
	check(ray_ok,"Slope collision follows exact surface and ignores ornament")
	var tops: Array=[5,5,5,5,4,4,4,4,4,4,3,2,2,2,2,2,2,3,4,4,4,4,4,4,5,5,5,5]
	var segments: Dictionary={4:[72,36],5:[36,0],10:[72,0],11:[72,0],16:[0,72],17:[0,72],22:[0,36],23:[36,72]}
	var joins_ok:=true
	for column in 28:
		for offset in [0.1,35.9]:
			var endpoints: Array=segments.get(column,[0,0])
			var y: float=route.position.y+tops[column]*36+(endpoints[0]+(endpoints[1]-endpoints[0])*offset/36)*0.5
			var x: float=route.position.x+column*36+offset
			var query:=PhysicsRayQueryParameters2D.create(Vector2(x,y-30),Vector2(x,y+30),2)
			var hit:=get_viewport().world_2d.direct_space_state.intersect_ray(query)
			joins_ok=joins_ok and not hit.is_empty() and abs(hit.position.y-y)<0.1
	check(joins_ok,"Joined floor profile has no gaps or invisible steps at cell boundaries")
	# Run the actual controller across every gentle/45-degree transition both ways.
	var start:=Vector2(116,1730)
	await place(start)
	await tick(30)
	Input.action_press("ui_right")
	var max_x:=player.position.x
	var min_floor_y:=player.position.y
	var trace: Array=[]
	for frame in 135:
		await tick()
		max_x=maxf(max_x,player.position.x)
		min_floor_y=minf(min_floor_y,player.position.y)
		if frame%15==0:trace.append([frame,player.position.x,player.position.y,player.is_on_floor()])
	Input.action_release("ui_right")
	print("SLOPE TRACE RIGHT: ",trace)
	check(max_x>1050 and min_floor_y<1680,"Unchanged player runs uphill, over 45 degrees, and downhill")
	await place(Vector2(1060,1720))
	await tick(30)
	Input.action_press("ui_left")
	var min_x:=player.position.x
	for frame in 135:
		await tick()
		min_x=minf(min_x,player.position.x)
	Input.action_release("ui_left")
	check(min_x<150,"Unchanged player crosses slopes in reverse")
	# A real jump from the floor, and left/right wall-jump contact.
	await place(Vector2(1050,1710))
	await tick(30)
	Input.action_press("jump")
	await tick(3)
	check(player.velocity.y<0,"Player jumps from native terrain")
	Input.action_release("jump")
	# Jump and brake onto the actual floating ledge at the end of the route.
	await place(Vector2(1450,1710))
	await tick(30)
	Input.action_press("ui_right")
	Input.action_press("jump")
	for frame in 40:
		await tick()
		if player.position.x>=1540:break
	Input.action_release("ui_right")
	Input.action_press("ui_left")
	await tick(5)
	Input.action_release("ui_left")
	Input.action_release("jump")
	await tick(60)
	check(player.is_on_floor() and player.position.y<1650 and player.position.x>1484 and player.position.x<1628,"Actual player jumps and lands on the floating ledge")
	for side in [-1,1]:
		await place(Vector2(1208 if side<0 else 1256,1680))
		Input.action_press("ui_left" if side<0 else "ui_right")
		await tick(8)
		Input.action_press("jump")
		await tick(2)
		check(player.is_wall_jumping and sign(player.velocity.x)==-side,"Native terrain wall jump side %d"%side)
		Input.action_release("jump")
		Input.action_release("ui_left")
		Input.action_release("ui_right")
	await place(Vector2(1209,1640))
	var climb_start:=player.position.y
	var wall_jumps:=0
	var wall_events: Array = []
	player.jumped.connect(func(from_wall):
		if from_wall:wall_events.append(player.position)
	)
	var climb_peak:=climb_start
	var last_side:=0
	Input.action_press("ui_left")
	for frame in 150:
		var side: int=player._wall_contact_side
		if side!=0 and side!=last_side and player.last_on_wall_time>0 and not player.is_on_floor():
			Input.action_release("jump")
			await tick()
			Input.action_press("jump")
			await tick()
			last_side=side
			wall_jumps+=1
			Input.action_release("ui_left")
			Input.action_release("ui_right")
			Input.action_press("ui_right" if side<0 else "ui_left")
		await tick()
		climb_peak=minf(climb_peak,player.position.y)
	print("SHAFT TRACE: ",wall_events," peak=",climb_peak)
	check(wall_events.size()>=3 and climb_peak<climb_start-150,"Repeated native wall jumps climb the shaft")
	for action in ["jump","ui_left","ui_right"]:Input.action_release(action)
	world.queue_free()
	await tick(90)
	print("GOTHIC RESULT: %d checks, %d failures"%[checks,failures.size()])
	var output: Dictionary={"checks":checks,"failures":failures,"engine":Engine.get_version_info(),"slope_trace":trace}
	var args:=OS.get_cmdline_user_args()
	if args.has("--output"):
		var file:=FileAccess.open(args[args.find("--output")+1],FileAccess.WRITE)
		file.store_string(JSON.stringify(output,"\t"))
	get_tree().quit(0 if failures.is_empty() else 1)
