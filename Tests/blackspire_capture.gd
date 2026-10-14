extends Node
func _ready()->void:run.call_deferred()
func run()->void:
	var args:=OS.get_cmdline_user_args()
	var output:String=args[args.find("--output")+1]
	var demo:bool=args.has("--demo")
	var world=load("res://Scenes/VisualDirectionTest.tscn" if demo else "res://World/World.tscn").instantiate()
	add_child(world)
	var player:Player=world.get_node("Player")
	await ticks(45)
	if args.has("--motion"):
		var shaft:bool=args.has("--shaft")
		if shaft:
			player.update_respawn_position(Vector2(1120,-100));player.respawn();await ticks(5)
		for frame in 180:
			if shaft:
				var left:bool=int(frame/24)%2==0
				Input.action_release("ui_right" if left else "ui_left")
				Input.action_press("ui_left" if left else "ui_right")
				if frame%24==6:Input.action_press("jump")
				if frame%24==18:Input.action_release("jump")
			else:
				Input.action_press("ui_right")
				if frame in [24,90]:Input.action_press("jump")
				if frame in [38,105]:Input.action_release("jump")
			await ticks(1)
			if frame%3==0:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(output.path_join("motion_%03d.png"%int(frame/3)))
		Input.action_release("ui_right");Input.action_release("ui_left");Input.action_release("jump")
		print("MOTION: actual player ends at ",player.position)
	else:
		player.set_physics_process(false)
		world.get_node("Camera2D").enabled=false
		world.get_node("Camera2D/PhantomCameraHost").queue_free();world.get_node("PhantomCamera2D").queue_free()
		var camera:=Camera2D.new();add_child(camera);camera.make_current()
		var shots:Array=[["entrance",Vector2(480,310),Vector2(140,456)],
			["vertical",Vector2(1160,160),Vector2(1120,20)],
			["open",Vector2(2180,-410),Vector2(2180,-504)]]
		for shot in shots:
			camera.position=shot[1];player.position=shot[2]
			camera.reset_physics_interpolation();player.reset_physics_interpolation()
			await ticks(3)
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(output.path_join(shot[0]+".png"))
	world.queue_free();await get_tree().process_frame;get_tree().quit()
func ticks(n:int)->void:
	for i in n:await get_tree().physics_frame;await get_tree().process_frame
