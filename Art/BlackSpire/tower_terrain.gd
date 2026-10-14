extends RefCounted
const QUIET=preload("res://Art/BlackSpire/Terrain/quiet_geometry.tres")
const EDGES=preload("res://Art/BlackSpire/terrain_edges.gd")
const DETAILS=preload("res://Art/BlackSpire/masonry_details.gd")
const SLOPES={Vector2i(0,0):1,Vector2i(2,0):2,Vector2i(0,2):3,Vector2i(2,2):4}
static func key(a:Vector2,b:Vector2)->String:
	var x:=Vector2i(a.round());var y:=Vector2i(b.round())
	if x.x>y.x or (x.x==y.x and x.y>y.y):
		var swap:=x;x=y;y=swap
	return "%d,%d/%d,%d"%[x.x,x.y,y.x,y.y]
static func visual_polygon(points:PackedVector2Array)->PackedVector2Array:
	var copy:=points.duplicate();var area:=0.0
	for i in copy.size():area+=copy[i].cross(copy[(i+1)%copy.size()])
	if area<0:copy.reverse()
	return copy
static func apply(original:TileMapLayer)->Node2D:
	var parent:=original.get_parent()
	var previous:=parent.get_node_or_null("BlackSpireTerrain")
	if previous:parent.remove_child(previous);previous.queue_free()
	var root:=Node2D.new();root.name="BlackSpireTerrain";parent.add_child(root)
	var layer:=TileMapLayer.new();layer.name="QuietStructure";layer.tile_set=QUIET
	layer.position=original.position;layer.rotation=original.rotation
	layer.scale=original.scale*16;layer.collision_enabled=false;layer.navigation_enabled=false
	layer.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;root.add_child(layer)
	var exposed:Dictionary={};var chunks:Dictionary={}
	var solids:Dictionary={}
	for cell in original.get_used_cells():
		if original.get_cell_atlas_coords(cell)==Vector2i(1,1):solids[cell]=true
	var details:=Node2D.new();details.name="MasonryAccents";details.set_script(DETAILS)
	details.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;root.add_child(details)
	for cell in solids:
		# An occasional embedded mark, well inside a mass; never a cell border.
		if posmod(cell.x+cell.y*3,11)!=0 or posmod(cell.y,5)!=0:continue
		var supported:=true
		for dx in range(-2,3):
			for dy in range(-1,2):
				if not solids.has(cell+Vector2i(dx,dy)):supported=false
		if supported:details.marks.append([original.transform*Vector2(original.map_to_local(cell)),posmod(cell.x+cell.y,3)])
	details.queue_redraw()
	for cell in original.get_used_cells():
		var data:=original.get_cell_tile_data(cell)
		var centre:=Vector2(original.map_to_local(cell))
		var world_centre:=original.transform*centre
		var band:=int(floor(world_centre.y/512))
		if not chunks.has(band):
			var edge:=Node2D.new();edge.set_script(EDGES);edge.name="Edges_%d"%band;edge.position.y=band*512
			edge.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;edge.z_index=1;root.add_child(edge);chunks[band]=edge
		var atlas:=original.get_cell_atlas_coords(cell)
		if data.get_collision_polygons_count(0)>0:
			var shape:int=SLOPES.get(atlas,0)
			layer.set_cell(cell,0,Vector2i(shape,0))
			var polygon:=visual_polygon(data.get_collision_polygon_points(0,0))
			for i in polygon.size():
				var a:=original.transform*(centre+polygon[i])
				var b:=original.transform*(centre+polygon[(i+1)%polygon.size()])
				var edge_key:=key(a,b)
				if exposed.has(edge_key):exposed.erase(edge_key)
				else:exposed[edge_key]=[a,b,shape,band,world_centre]
		if data.get_collision_polygons_count(1)>0:
			for i in data.get_collision_polygons_count(1):
				var points:=PackedVector2Array()
				for p in data.get_collision_polygon_points(1,i):points.append(original.transform*(centre+p)-chunks[band].position)
				chunks[band].hazards.append(points)
	for item in exposed.values():
		var a:Vector2=item[0];var b:Vector2=item[1]
		var band:int=item[3];var edge:Node2D=chunks[band]
		if is_equal_approx(a.x,b.x) or is_equal_approx(a.y,b.y):
			edge.edges.append([a-edge.position,b-edge.position])
		else:
			var centre:Vector2=item[4]
			edge.slopes.append([Rect2(centre-Vector2.ONE*16-edge.position,Vector2.ONE*32),item[2]])
	for edge in chunks.values():edge.queue_redraw()
	# No changes to cells, colliders, material data or platform physics.
	original.modulate.a=0.0
	return root
