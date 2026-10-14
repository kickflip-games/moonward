extends Node
const FRAMES=preload("res://Art/Characters/N3Cloud/character_frames.tres")
var checks:int=0
var failures:Array[String]=[]
func check(value:bool,label:String)->void:
	checks+=1
	if not value:failures.append(label);push_error("FAIL: "+label)
func tick(n:int=1)->void:
	for i in n:await get_tree().physics_frame;await get_tree().process_frame
func release()->void:
	for action in ["ui_left","ui_right","jump"]:Input.action_release(action)
func place(player:Player,at:Vector2,settle:int=25)->void:
	release();player.update_respawn_position(at);player.respawn();await tick(settle)
func _ready()->void:run.call_deferred()
func run()->void:
	var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://Art/Characters/N3Cloud/animation_manifest.json"))
	var valid_rects:=true
	for animation in manifest.animations:
		check(FRAMES.get_frame_count(animation.name)==animation.frame_count and FRAMES.get_animation_loop(animation.name)==animation.loop,"Frame count / looping "+animation.name)
		for i in animation.frame_count:
			var texture:AtlasTexture=FRAMES.get_frame_texture(animation.name,i)
			var xy:Array=animation.coordinates[i]
			valid_rects=valid_rects and texture.region==Rect2(xy[0]*128,xy[1]*80,128,80) and texture.filter_clip
	check(valid_rects,"Every animation retains fixed 128x80 regions, clipping and source coordinates")
	var scene=load("res://Scenes/CharacterMovementTest.tscn").instantiate();add_child(scene);await tick(40)
	var player:Player=scene.get_node("Player");var visual=player.get_node("Sprite")
	check(visual.sprite.visible and not visual.cube.visible,"Exactly one character visual is active")
	check(not player.has_node("AnimationPlayer"),"No obsolete polygon AnimationPlayer tracks")
	check(player.get_node("SquareCollisionShape").shape.size==Vector2(26,24) and player.get_node("SquareCollisionShape").position==Vector2(0,-4),"Original 26x24 collider and offset preserved")
	check(visual.sprite.offset==Vector2(-64,-64) and not visual.sprite.centered,"Fixed foot anchor, independent of frame bounds")
	check(scene.get_node("Springboard").bounce_force==2500,"Test spring uses existing force")
	var ground:=StaticBody2D.new();ground.position=Vector2(6000,512);ground.collision_layer=2
	var collider:=CollisionShape2D.new();var box:=RectangleShape2D.new();box.size=Vector2(2400,64)
	collider.shape=box;ground.add_child(collider);add_child(ground)
	await place(player,Vector2(5200,472))
	check(visual.visual_state=="idle" and visual.modulate.a==1,"Respawn becomes visible idle without animation locks")
	Input.action_press("ui_right");await tick(4)
	check(visual.visual_state=="run","Actual low-speed movement selects run frames")
	await tick(8)
	check(visual.visual_state=="sprint" and visual.sprite.speed_scale<=1.3,"Full speed selects bounded sprint playback")
	check(absf(visual.rotation_degrees)<=visual.run_lean_degrees+.01,"Running lean stays below five degrees")
	var fx_before:int=visual.jump_fx_count;var roll_before:int=visual.somersault_count
	Input.action_press("jump");await tick(2)
	check(visual.visual_state=="takeoff" and visual.squash_root.scale.y>1,"Actual jump starts sprite pose and subtle stretch")
	check(visual.jump_fx_count==fx_before+1,"One sound/particle dispatch per physics jump signal")
	await tick(14)
	check(visual.somersault_active and visual.current_animation=="air_roll","Fast open-air jump selects actual roll frames")
	check(visual.rotation==0,"In-frame roll does not receive a second procedural spin")
	await tick(12);release()
	for i in 55:
		await tick()
		if player.is_on_floor():break
	await tick(12)
	check(visual.somersault_count==roll_before+1,"One flourish per airborne sequence")
	check(player.is_on_floor() and not visual.somersault_active,"Landing immediately clears airborne flourish")
	check(visual.squash_root.scale.is_equal_approx(Vector2.ONE),"Landing tween returns to a known baseline")
	check(visual.landing_fx_count>0,"Landing effects are preserved")
	Input.action_press("ui_right");await tick(12);Input.action_press("jump");await tick(16)
	check(visual.somersault_count==roll_before+1,"Consecutive fast jumps respect the flourish cooldown decided at takeoff")
	release();await tick(55)
	await place(player,Vector2(5200,472));roll_before=visual.somersault_count
	Input.action_press("jump");await tick(35);Input.action_release("jump");await tick(30)
	check(visual.somersault_count==roll_before,"Standing jumps do not automatically somersault")
	# A launch in clear air stays visual only and keeps the actual source direction.
	await place(player,Vector2(5400,200))
	fx_before=visual.jump_fx_count;player.launch(Vector2(560,-2500));await tick(1)
	check(visual.visual_state=="spring_launch" and visual.jump_fx_count==fx_before+1,"Spring launch uses one energetic pose/effect dispatch")
	await tick(15)
	check(visual.somersault_active,"Clear spring launch can flourish")
	# Real contacts in the inherited narrow shaft suppress the flourish.
	await place(player,Vector2(1120,-100),5)
	Input.action_press("ui_left");await tick(6);Input.action_press("jump");await tick(2)
	check(player.velocity.x>0 and visual.facing==1 and visual.visual_state=="wall_jump","Left-wall jump faces actual outgoing velocity")
	release();await tick(10)
	check(not visual.somersault_active,"Narrow wall-jump shaft suppresses rolling")
	await place(player,Vector2(1184,-100),5)
	Input.action_press("ui_right");await tick(6);Input.action_press("jump");await tick(2)
	check(player.velocity.x<0 and visual.facing==-1,"Right-wall jump faces actual outgoing velocity")
	release()
	await place(player,Vector2(1120,-160),5);Input.action_press("ui_left");await tick(8)
	check(player.is_sliding and visual.visual_state=="wall_slide" and visual.facing_root.position.x<0,"Actual wall slide uses contact pose and art-only alignment")
	release();await place(player,Vector2(5200,472))
	visual.set_cube_fallback(true)
	check(not visual.sprite.visible and visual.cube.visible,"Cube debug switch shows only the fallback")
	visual.set_cube_fallback(false)
	check(visual.sprite.visible and not visual.cube.visible,"Character returns without duplicate visuals")
	player._grace_timer=0;player.die();player.die();await tick(7)
	check(visual.visual_state=="death" and not visual.somersault_active and visual.modulate.a<1,"Death preempts animation and fades quickly")
	check(visual.speed_trail.get_point_count()==0 and visual.roll_trail.get_point_count()==0,"Death clears stale momentum trails")
	await tick(50)
	check(not player.is_dead and visual.sprite.visible and visual.modulate.a>.99,"Rapid retry restores visibility without a delayed hide")
	check(visual.rotation==0 and visual.facing_root.scale==Vector2.ONE and visual.squash_root.scale.is_equal_approx(Vector2.ONE),"Respawn resets rotation, facing, squash and locks")
	check(player.scale==Vector2.ONE and player.rotation==0,"Procedural transforms never reach the physics body")
	# Preview is independently usable and both preview sizes step together.
	var preview=load("res://Scenes/CharacterAnimationTest.tscn").instantiate();add_child(preview);await tick(2)
	preview._step(1)
	check(preview.character.frame==preview.small.frame and preview.paused,"Preview pause/step keeps both scales on the same frame")
	preview._select(preview.names.find("roll__roll"));preview.playback=.5;preview._apply_speed()
	check(preview.character.animation==&"roll__roll" and preview.character.speed_scale==0,"Preview can select the full author roll while paused")
	preview.queue_free();scene.queue_free();ground.queue_free();await tick(5)
	print("CHARACTER RESULT: %d checks, %d failures"%[checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
