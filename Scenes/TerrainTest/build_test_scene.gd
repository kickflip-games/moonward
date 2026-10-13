extends Node

const TERRAIN = preload("res://Art/Dungeon/Terrain/gothic_terrain.tres")
const DECOR = preload("res://Art/Dungeon/Terrain/decorations.tres")
const WORLD_CELL = 36.0
var scene: Node2D
var meta: Dictionary

func layer(name: String, origin: Vector2, decoration: bool = false) -> TileMapLayer:
	var node := TileMapLayer.new()
	node.name = name
	node.tile_set = DECOR if decoration else TERRAIN
	node.position = origin
	node.scale = Vector2.ONE * 0.5
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scene.add_child(node)
	node.owner = scene
	return node

func paint(node: TileMapLayer, cells: Array[Vector2i], style: int) -> void:
	node.set_cells_terrain_connect(cells,style,0,false)

func rectangle(x: int,y: int,w: int,h: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cy in range(y,y+h):
		for cx in range(x,x+w):
			cells.append(Vector2i(cx,cy))
	return cells

func find_tile(style: int, name: String) -> Vector2i:
	for tile in meta.styles[style].tiles:
		if tile.name == name:
			return Vector2i(tile.atlas_coords[0],tile.atlas_coords[1])
	return Vector2i(-1,-1)

func prop(node: TileMapLayer, cell: Vector2i, name: String) -> void:
	for tile in meta.decorations:
		if tile.name == name:
			node.set_cell(cell,0,Vector2i(tile.atlas_coords[0],tile.atlas_coords[1]))
			return

func label(text: String, pos: Vector2) -> void:
	var node := Label.new()
	node.text = text
	node.position = pos
	node.add_theme_font_size_override("font_size",20)
	node.modulate = Color("cbddea")
	scene.add_child(node)
	node.owner = scene

func manual(node: TileMapLayer,cell: Vector2i,style: int,name: String) -> void:
	node.set_cell(cell,style,find_tile(style,name))

func slope_course(node: TileMapLayer, style: int, row: int = 5) -> void:
	# Paint complete occupied topology first, then replace partial cells manually.
	# This keeps buried faces bare even beside manual slope cells.
	var tops := [5,5,5,5,4,4,4,4,4,4,3,2,2,2,2,2,2,3,4,4,4,4,4,4,5,5,5,5]
	var cells: Array[Vector2i] = []
	for x in tops.size():
		cells.append_array(rectangle(x,tops[x]+row-5,1,8-tops[x]))
	paint(node,cells,style)
	for item in [[4,4,"up_gentle_low"],[5,4,"up_gentle_high"],[10,3,"up_45"],[11,2,"up_45"],
		[16,2,"down_45"],[17,3,"down_45"],[22,4,"down_gentle_high"],[23,4,"down_gentle_low"]]:
		manual(node,Vector2i(item[0],item[1]+row-5),style,item[2])
	for x in [3,6,9,12,15,18,21,24]:
		manual(node,Vector2i(x,tops[x]+row-5),style,"flat_transition")

func _ready() -> void:
	seed(17014)
	meta = JSON.parse_string(FileAccess.get_file_as_string("res://Art/Dungeon/Terrain/terrain_atlas.json"))
	scene = Node2D.new()
	scene.name = "GothicTerrainTest"
	scene.set_script(load("res://Scenes/TerrainTest/test_scene.gd"))
	var walls := layer("LargeMossWall",Vector2(80,100))
	paint(walls,rectangle(0,0,8,6),0)
	var previous := layer("PreviousWall",Vector2(80,100))
	previous.tile_set = load("res://Art/StoneSheet/stone_tileset.tres")
	previous.scale = Vector2.ONE * 0.45
	previous.collision_enabled = false
	paint(previous,rectangle(0,0,8,6),0)
	previous.visible = false
	label("A / Continuous masonry — 8 × 6",Vector2(80,55))
	var ice := layer("LargeIceWall",Vector2(440,100))
	paint(ice,rectangle(0,0,8,6),1)
	label("A / Snow surfaces",Vector2(440,55))
	var mixed := layer("MixedMaterials",Vector2(820,100))
	paint(mixed,rectangle(0,0,5,6),0)
	paint(mixed,rectangle(5,0,5,6),1)
	manual(mixed,Vector2i(4,0),0,"bare_top")
	manual(mixed,Vector2i(5,0),1,"bare_top")
	label("G / Deliberate material boundary",Vector2(820,55))
	for style in 2:
		var origin := Vector2(80+style*540,440)
		var wall := layer("MossEnvironment" if style==0 else "SnowEnvironment",origin)
		var cells := rectangle(0,0,13,9)
		for hole in rectangle(4,3,4,3):
			cells.erase(hole)
		for cut in rectangle(0,0,3,2):
			cells.erase(cut)
		for cut in rectangle(10,0,3,1):
			cells.erase(cut)
		cells.append_array(rectangle(13,4,2,2))
		cells.append_array(rectangle(2,-1,4,1))
		paint(wall,cells,style)
		var deco := layer("MossDecorations" if style==0 else "SnowDecorations",origin,true)
		deco.z_index = 1
		prop(deco,Vector2i(3,3),"moon_banner_moss" if style==0 else "moon_banner_ice")
		prop(deco,Vector2i(10,4),"window_moss" if style==0 else "moon_window_ice")
		prop(deco,Vector2i(1,6),"pillar_moss" if style==0 else "pillar_ice")
		prop(deco,Vector2i(6,8),"shrine_moss" if style==0 else "shrine_ice")
		prop(deco,Vector2i(6,2),"lantern_moss" if style==0 else "lantern_ice")
		if style==0:
			prop(deco,Vector2i(3,1),"hanging_vine")
			prop(deco,Vector2i(9,2),"wall_chain")
		label("B / E / Moss — corners, hole, decorations" if style==0 else "B / F / Ice — corners, hole, decorations",origin-Vector2(0,70))
	var floating := layer("FloatingPlatforms",Vector2(80,835))
	for i in 4:
		paint(floating,rectangle(i*4,i%2, i+1,1),i%2)
	paint(floating,rectangle(0,4,1,4),0)
	paint(floating,rectangle(4,3,7,1),0)
	paint(floating,rectangle(7,1,1,6),0)
	label("C / Single blocks, ledges, pillar and T-junction",Vector2(80,795))
	var slopes := layer("SlopeDemonstration",Vector2(480,880))
	slope_course(slopes,1)
	label("D / Gentle and 45° slopes — exact continuous endpoints",Vector2(480,820))
	var route := layer("GameplayRoute",Vector2(80,1600))
	slope_course(route,0)
	paint(route,rectangle(-2,5,2,3),0)
	paint(route,rectangle(30,5,9,3),0)
	paint(route,rectangle(30,-6,1,11),0)
	paint(route,rectangle(33,-7,1,12),0)
	paint(route,rectangle(36,2,1,3),0)
	paint(route,rectangle(39,1,4,1),0)
	label("H / Player route — arrows + jump; Esc retry; 1–4 inspect; 5 follow",Vector2(80,1560))
	var player = load("res://Player/Player.tscn").instantiate()
	player.name = "Player"
	player.position = Vector2(116,1730)
	scene.add_child(player)
	player.owner = scene
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	scene.add_child(camera)
	camera.owner = scene
	var background := CanvasLayer.new()
	background.name = "Backdrop"
	background.layer = -10
	scene.add_child(background)
	background.owner = scene
	var rect := ColorRect.new()
	rect.name = "Night"
	rect.color = Color("101621")
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.add_child(rect)
	rect.owner = scene
	var packed := PackedScene.new()
	packed.pack(scene)
	var error := ResourceSaver.save(packed,"res://Scenes/TerrainTest/GothicTerrainTest.tscn")
	print("GOTHIC SCENE: test layouts saved")
	scene.free()
	get_tree().quit(0 if error==OK else 1)
