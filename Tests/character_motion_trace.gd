extends Node
var player:Player
var trace:Dictionary={}
func _ready()->void:run.call_deferred()
func tick(n:int=1)->void:
	for i in n:await get_tree().physics_frame;await get_tree().process_frame
func release()->void:
	for action in ["ui_left","ui_right","jump"]:Input.action_release(action)
func place(at:Vector2,settle:int=5)->void:
	release();player.update_respawn_position(at);player.respawn();await tick(settle)
func sample()->Array:
	return [player.position.x,player.position.y,player.velocity.x,player.velocity.y,player.is_on_floor(),player.is_on_wall(),player.is_dead]
func segment(name:String,n:int)->void:
	var values:Array=[]
	for i in n:await tick();values.append(sample())
	trace[name]=values
func run()->void:
	var scene=load("res://Tests/MovementTest.tscn").instantiate();add_child(scene);await tick(5)
	player=scene.get_node("Player")
	await place(Vector2(0,-8),20)
	Input.action_press("ui_right");await segment("acceleration",20)
	Input.action_release("ui_right");Input.action_press("ui_left");await segment("reversal",20)
	await place(Vector2(0,-8),20);Input.action_press("jump");await segment("full_jump",45)
	await place(Vector2(0,-8),20);Input.action_press("jump");await segment("short_jump_held",4)
	Input.action_release("jump");await segment("short_jump_cut",40)
	await place(Vector2(2500,-40));Input.action_press("ui_left");await tick(8)
	Input.action_press("jump");await segment("wall_jump",25)
	await place(Vector2(5200,-80),15);await segment("moving_platform",50)
	await place(Vector2(6100,-80),5);await segment("spring",45)
	await place(Vector2(0,-8),20);player._grace_timer=0;player.die();await segment("death_retry",50)
	release()
	var args:=OS.get_cmdline_user_args();var file:=FileAccess.open(args[args.find("--output")+1],FileAccess.WRITE)
	file.store_string(JSON.stringify(trace,"\t"))
	print("CHARACTER TRACE: ",trace.size()," reproducible physics segments")
	scene.queue_free();await tick(5);get_tree().quit()
