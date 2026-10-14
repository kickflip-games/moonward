extends Node
var world:Node2D
var player:Player
var camera:Camera2D
var output:String
var record:bool=false
var frame_count:int=0
var samples:Array=[]
func _ready()->void:
	process_mode=Node.PROCESS_MODE_ALWAYS;run.call_deferred()
func tick(n:int=1)->void:
	for i in n:
		await get_tree().physics_frame;await get_tree().process_frame
		if record and Engine.get_physics_frames()%3==0:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(output.path_join("motion_%04d.png"%frame_count));frame_count+=1
func release()->void:
	for action in ["ui_left","ui_right","jump"]:Input.action_release(action)
func place(at:Vector2,settle:int=25)->void:
	release();player.update_respawn_position(at);player.respawn();await tick(settle)
func shot(name:String,centre:Vector2)->void:
	camera.position=centre;camera.reset_physics_interpolation()
	get_tree().paused=true
	await RenderingServer.frame_post_draw;await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join(name+".png"))
	var visual=player.get_node("Sprite")
	var modern:bool=visual.has_method("set_cube_fallback")
	samples.append({"name":name,"position":[player.position.x,player.position.y],"velocity":[player.velocity.x,player.velocity.y],"animation":visual.current_animation,"state":visual.visual_state if modern else "legacy cube","frame":visual.sprite.frame if modern else -1})
	print("CAPTURED ",name," ",samples[-1])
	get_tree().paused=false
func run()->void:
	var args:=OS.get_cmdline_user_args();output=args[args.find("--output")+1]
	if args.has("--preview"):
		var preview=load("res://Scenes/CharacterAnimationTest.tscn").instantiate();add_child(preview)
		await tick(3);preview._select(preview.names.find("roll__roll"));await tick(20)
		preview._toggle_pause();await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(output.path_join("animation_preview.png"))
		preview.queue_free();await get_tree().process_frame;get_tree().quit();return
	record=args.has("--motion")
	world=load("res://Scenes/CharacterMovementTest.tscn").instantiate();add_child(world)
	player=world.get_node("Player");world.get_node("GameHud/MobileInputs").hide()
	world.get_node("Camera2D").enabled=false
	world.get_node("Camera2D/PhantomCameraHost").queue_free();world.get_node("PhantomCamera2D").queue_free()
	camera=Camera2D.new();camera.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(camera);camera.make_current()
	# A native colliding test floor beside the three existing bays, no tower edits.
	var floor:=TileMapLayer.new();floor.tile_set=load("res://Art/BlackSpire/Terrain/medieval_terrain.tres")
	floor.scale=Vector2.ONE*2;floor.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;world.add_child(floor)
	var cells:Array[Vector2i]=[]
	for x in range(-32,-4):
		for y in range(10,14):cells.append(Vector2i(x,y))
	floor.set_cells_terrain_connect(cells,0,0,false)
	# An intentional architectural landmark keeps the comparison in the new style.
	var door:=Sprite2D.new();door.texture=load("res://Art/BlackSpire/Props/regions/door_open.tres")
	door.scale=Vector2.ONE*2;door.position=Vector2(-1150,424);door.z_index=-2
	door.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;world.add_child(door)
	camera.position=Vector2(-1020,240);await place(Vector2(-1300,472),40)
	await shot("01_idle",Vector2(-1050,240))
	Input.action_press("ui_right");await tick(4);await shot("02_running",Vector2(-1050,240))
	await tick(8);await shot("03_full_speed",Vector2(-1050,240))
	await place(Vector2(-1300,472));Input.action_press("jump");await tick(2)
	await shot("04_jump",Vector2(-1050,240));release();await tick(70)
	await place(Vector2(-1300,472));Input.action_press("ui_right");await tick(12)
	Input.action_press("jump");await tick(8);await shot("05_long_jump",Vector2(-1050,240))
	await tick(8);await shot("06_somersault",Vector2(-1050,240));release();await tick(60)
	camera.position=Vector2(1160,60);await place(Vector2(1120,-160),5)
	Input.action_press("ui_left");await tick(8);await shot("07_wall_slide",Vector2(1160,60))
	Input.action_press("jump");await tick(2);await shot("08_wall_jump",Vector2(1160,60));release()
	camera.position=Vector2(680,200);await place(Vector2(648,330),5)
	for i in 50:
		await tick()
		if player._spring_launch:break
	await shot("09_springboard",Vector2(680,200));release()
	camera.position=Vector2(-1050,240);await place(Vector2(-1150,100),5)
	for i in 70:
		await tick()
		if player.is_on_floor():break
	await shot("10_landing",Vector2(-1050,240));await tick(30)
	player._grace_timer=0;player.die();await tick(5);await shot("11_death",Vector2(-1050,240))
	for i in 35:
		await tick()
		if not player.is_dead:break
	await tick(2);await shot("12_respawn",Vector2(-1050,240));await tick(20)
	var file:=FileAccess.open(output.path_join("states.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(samples,"\t"));release()
	world.queue_free();camera.queue_free();await get_tree().process_frame;get_tree().quit()
