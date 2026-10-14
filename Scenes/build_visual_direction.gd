extends Node
const TERRAIN=preload("res://Art/BlackSpire/Terrain/medieval_terrain.tres")
const SURFACE=preload("res://Art/BlackSpire/surface_material.gd")
var scene:Node2D
var ground:TileMapLayer
var meta:Dictionary
func rectangle(x:int,y:int,w:int,h:int)->Array[Vector2i]:
	var out:Array[Vector2i]=[]
	for cy in range(y,y+h):
		for cx in range(x,x+w):out.append(Vector2i(cx,cy))
	return out
func paint(cells:Array[Vector2i])->void:ground.set_cells_terrain_connect(cells,0,0,false)
func tile(cell:Vector2i,name:String)->void:
	for item in meta.terrain_tiles:
		if item.name==name:ground.set_cell(cell,0,Vector2i(item.atlas_coords[0],item.atlas_coords[1]));return
func add_node(node:Node,name:String,pos:Vector2)->void:
	node.name=name
	if node is Node2D:node.position=pos
	scene.add_child(node);node.owner=scene
func prop(name:String,point:Vector2,tint:Color=Color.WHITE)->void:
	var sprite:=Sprite2D.new();sprite.texture=load("res://Art/BlackSpire/Props/regions/"+name+".tres")
	sprite.z_index=-2
	if name=="window":sprite.z_index=1
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;sprite.scale=Vector2.ONE*2;sprite.modulate=tint
	add_node(sprite,"Detail_"+name,point)
func checkpoint(point:Vector2,index:int)->void:
	var node=load("res://Checkpoint/Checkpoint.tscn").instantiate()
	node.progression_index=index
	add_node(node,"Checkpoint_%d"%index,point)
func _ready()->void:
	seed(17)
	meta=JSON.parse_string(FileAccess.get_file_as_string("res://Art/BlackSpire/catalog.json"))
	scene=Node2D.new();scene.name="VisualDirectionTest";scene.set_script(load("res://Scenes/visual_direction_test.gd"))
	ground=TileMapLayer.new();ground.tile_set=TERRAIN;ground.scale=Vector2.ONE*2
	ground.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	add_node(ground,"MainTerrain",Vector2.ZERO)
	# Entrance: a quiet 20x20 masonry mass, floor and original gentle incline.
	paint(rectangle(0,10,20,20))
	paint(rectangle(13,9,7,1))
	for item in [[10,9,"up_gentle_low"],[11,9,"up_gentle_middle"],[12,9,"up_gentle_high"]]:
		tile(Vector2i(item[0],item[1]),item[2])
	paint(rectangle(16,6,4,1))
	prop("door_open",Vector2(192,424));prop("torch",Vector2(100,449));prop("barrel",Vector2(270,454))
	prop("window",Vector2(600,560),Color(.55,.55,.8))
	prop("pillar",Vector2(790,340),Color(.65,.65,.8))
	checkpoint(Vector2(336,480),0)
	# Occasional original masonry accents demonstrate quiet large structural fills.
	var marks:=Node2D.new();marks.set_script(load("res://Art/BlackSpire/masonry_details.gd"))
	marks.marks=[[Vector2(180,660),0],[Vector2(680,760),1],[Vector2(420,1010),2]]
	marks.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;add_node(marks,"EmbeddedMasonry",Vector2.ZERO)
	# Vertical challenge: wall-jump shaft, one moving wooden lift, hazard and safe shelf.
	paint(rectangle(22,-5,1,15));paint(rectangle(25,-8,1,18));paint(rectangle(25,-8,6,1))
	paint(rectangle(20,10,12,6))
	var moving=load("res://Platforms/MovingPlatform.tscn").instantiate()
	moving.move_to=Vector2(0,-96);moving.show_path=false;moving.modulate=Color.WHITE
	SURFACE.skin(moving.get_node("ActualPlatform/Polygon2D"),SURFACE.PLANKS)
	add_node(moving,"WoodenLift",Vector2(1152,100))
	var spike=load("res://Enemies/Spikes/spikes.tscn").instantiate()
	spike.modulate=Color.WHITE
	for visual in spike.get_node("Visuals").get_children():SURFACE.skin(visual,SURFACE.SPIKE,true)
	add_node(spike,"SpikeHazard",Vector2(1392,470))
	prop("ladder",Vector2(984,150),Color(.35,.35,.5))
	prop("pillar",Vector2(1336,-300),Color(.55,.55,.75))
	prop("window",Vector2(1054,160),Color(.5,.55,.8))
	checkpoint(Vector2(1320,-384),1)
	# Open traversal: deliberate long gaps, roof-derived 45-degree slopes, few props.
	paint(rectangle(34,-8,5,3));paint(rectangle(42,-10,5,3));paint(rectangle(50,-12,6,3))
	paint(rectangle(39,-8,2,3));paint(rectangle(40,-9,1,1));paint(rectangle(41,-10,1,5))
	tile(Vector2i(39,-9),"up_45");tile(Vector2i(40,-10),"up_45")
	paint(rectangle(58,-13,5,1))
	prop("left_arch_trim",Vector2(1680,-320),Color(.5,.5,.7))
	prop("right_arch_trim",Vector2(1824,-320),Color(.5,.5,.7))
	checkpoint(Vector2(2592,-576),2)
	var player=load("res://Player/Player.tscn").instantiate();add_node(player,"Player",Vector2(140,456))
	var camera:=Camera2D.new();camera.position=Vector2(140,386);camera.limit_left=-200;camera.limit_right=3400;camera.limit_bottom=1900
	add_node(camera,"Camera2D",camera.position)
	var host:=Node.new();host.name="PhantomCameraHost";host.set_script(load("res://addons/phantom_camera/scripts/phantom_camera_host/phantom_camera_host.gd"))
	camera.add_child(host);host.owner=scene;host.process_priority=300;host.process_physics_priority=300
	var phantom:=Node2D.new();phantom.set_script(load("res://addons/phantom_camera/scripts/phantom_camera/phantom_camera_2d.gd"))
	add_node(phantom,"PhantomCamera2D",Vector2(140,386));phantom.follow_mode=2;phantom.follow_target=player;phantom.priority=1
	phantom.follow_damping=true;phantom.follow_damping_value=Vector2(.09,.06)
	var look:=Node.new();look.set_script(load("res://World/CameraLookahead.gd"));phantom.add_child(look);look.owner=scene
	var background:=Node2D.new();background.set_script(load("res://Art/BlackSpire/background.gd"))
	background.centre_x=1300; background.opening_height=200; background.height_span=500;add_node(background,"TowerDepth",Vector2.ZERO)
	var hud=load("res://World/game_hud.tscn").instantiate();add_node(hud,"GameHud",Vector2.ZERO)
	var packed:=PackedScene.new();packed.pack(scene)
	var error:=ResourceSaver.save(packed,"res://Scenes/VisualDirectionTest.tscn")
	# Prefab checkpoint connections are inherited; packing also writes redundant copies.
	var text:=FileAccess.get_file_as_string("res://Scenes/VisualDirectionTest.tscn")
	var cleaned:Array[String]=[]
	for line in text.split("\n"):
		if line.begins_with("[connection") and 'from="Checkpoint_' in line:continue
		cleaned.append(line)
	var file:=FileAccess.open("res://Scenes/VisualDirectionTest.tscn",FileAccess.WRITE)
	file.store_string("\n".join(cleaned).strip_edges()+"\n")
	scene.free();print("BLACKSPIRE TEST SCENE saved")
	get_tree().quit(0 if error==OK else 1)
