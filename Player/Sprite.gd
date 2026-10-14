extends Node2D
## One visual owner. This script reads physics state and never writes the body.
@export var player_path:NodePath
@export var visual_scale:float=0.75
@export var debug_cube:bool=false
@export var show_visual_debug:bool=false
@export_group("Procedural presentation")
@export var run_lean_degrees:float=4.0
@export var jump_stretch:=Vector2(.90,1.10)
@export var land_squash:=Vector2(1.12,.86)
@export var wall_contact_offset:float=4.0
@export_group("Airborne flourish")
@export var somersault_min_speed:float=500.0
@export var somersault_air_delay:float=.18
@export var somersault_wall_clearance:float=64.0
@export var somersault_cooldown:float=1.4
@export var allow_somersaults:bool=true

@onready var player:Player=get_node(player_path)
@onready var facing_root:Node2D=$FacingRoot
@onready var squash_root:Node2D=$FacingRoot/SquashRoot
@onready var sprite:AnimatedSprite2D=$FacingRoot/SquashRoot/Character
@onready var cube:Polygon2D=$FacingRoot/SquashRoot/CubeFallback
@onready var jump_sfx:AudioStreamPlayer2D=$"../Sfx/JumpSFX"
@onready var land_sfx:AudioStreamPlayer2D=$"../Sfx/LandSFX"
@onready var footstep_sfx:AudioStreamPlayer2D=$"../Sfx/FootstepSFX"
@onready var wall_slide_sfx:AudioStreamPlayer2D=$"../Sfx/WallslideSFX"
@onready var death_sfx:AudioStreamPlayer2D=$"../Sfx/DeathSFX"
@onready var spawn_sfx:AudioStreamPlayer2D=$"../Sfx/SpawnSFX"
@onready var jump_particles:CPUParticles2D=$"../ParticleFx/JumpFx"
@onready var land_particles:CPUParticles2D=$"../ParticleFx/LandFx"
@onready var run_particles:CPUParticles2D=$"../ParticleFx/RunFx"
@onready var wall_particles:CPUParticles2D=$"../ParticleFx/WallslideFx"
@onready var death_particles:CPUParticles2D=$"../ParticleFx/DeathFx"
@onready var spawn_particles:CPUParticles2D=$"../ParticleFx/SpawnFx"
@onready var roll_trail:Line2D=$"../Trails/SomersaultTrail"
@onready var speed_trail:Line2D=$"../Trails/SpeedTrail"

var visual_state:String="respawn"
var current_animation:String=""
var previous_velocity:=Vector2.ZERO
var previous_grounded:bool=false
var air_time:float=0
var takeoff_speed:float=0
var takeoff_kind:String="jump"
var lock_state:String=""
var lock_time:float=0
var spawn_time:float=0
var death_time:float=0
var somersault_active:bool=false
var somersault_used:bool=false
var flourish_wait:float=0
var flourish_eligible:bool=false
var somersault_count:int=0
var jump_fx_count:int=0
var landing_fx_count:int=0
var facing:int=1
var wall_jump_facing:int=1
var squash_tween:Tween
var footstep_cooldown:float=0
var trail_clock:float=0
var debug_label:Label

func _ready()->void:
	sprite.scale=Vector2.ONE*visual_scale
	for fx in [jump_particles,land_particles,run_particles,wall_particles,death_particles,spawn_particles]:
		fx.emitting=false;fx.rotation=0;fx.position=Vector2(0,8)
		fx.scale_amount_min=.10;fx.scale_amount_max=.22
		fx.color=Color(.72,.84,1,.7);fx.gravity=Vector2(0,120)
		fx.lifetime=.24;fx.emission_sphere_radius=4
		fx.initial_velocity_min=20;fx.initial_velocity_max=70
	jump_particles.amount=8;land_particles.amount=8;run_particles.amount=5
	wall_particles.amount=5;death_particles.amount=14;spawn_particles.amount=8
	death_particles.lifetime=.3;spawn_particles.lifetime=.18
	death_particles.position=Vector2(0,-5);spawn_particles.position=Vector2(0,-5)
	for trail in [roll_trail,speed_trail]:
		trail.width=3;trail.gradient=null
		trail.default_color=Color(.55,.73,1,.22);trail.clear_points();trail.hide()
	player.jumped.connect(_on_player_jumped)
	player.died.connect(_on_player_died)
	player.respawned.connect(_on_player_respawned)
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)
	debug_label=Label.new();debug_label.position=Vector2(-95,-100)
	debug_label.add_theme_font_size_override("font_size",11);debug_label.z_index=20
	debug_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(debug_label)
	_apply_visual_mode();_select("respawn")

func _physics_process(delta:float)->void:
	lock_time=maxf(0,lock_time-delta);spawn_time=maxf(0,spawn_time-delta)
	footstep_cooldown=maxf(0,footstep_cooldown-delta)
	flourish_wait=maxf(0,flourish_wait-delta)
	var grounded:bool=player.is_on_floor() and player.velocity.y>=0
	if player.is_dead:
		death_time+=delta;somersault_active=false
		modulate.a=clampf(1-(death_time-.06)/.10,0,1)
		_select("death");_stop_continuous_fx();_clear_trails()
	else:
		modulate.a=clampf(1-spawn_time/.12*.7,.3,1)
		if grounded:
			if not previous_grounded and previous_velocity.y>120 and spawn_time<=0:
				_land(previous_velocity.y)
			air_time=0;somersault_used=false;somersault_active=false
		else:air_time+=delta
		if player._wall_contact_side!=0 or player.is_sliding or player.is_wall_jumping:
			somersault_active=false
		if _can_somersault(grounded):
			somersault_active=true;somersault_used=true;somersault_count+=1
			flourish_wait=somersault_cooldown
		_select(_choose_state(grounded))
		_update_facing()
		var lean:float=deg_to_rad(run_lean_degrees*facing) if visual_state in ["run","sprint"] else 0
		# The source roll already rotates. No additional procedural spin.
		rotation=lerp_angle(rotation,lean,minf(1,delta*18)) if visual_state in ["run","sprint","idle"] else 0
		_update_continuous_fx(delta,grounded)
	previous_grounded=grounded;previous_velocity=player.velocity
	_apply_visual_mode();_update_debug()

func _choose_state(grounded:bool)->String:
	if spawn_time>0:return "respawn"
	if player.is_wall_jumping:return "wall_jump"
	if player.is_sliding:return "wall_slide"
	if somersault_active:return "somersault"
	if not grounded:
		if lock_time>0 and lock_state in ["takeoff","wall_jump","spring_launch"]:return lock_state
		if player.velocity.y < -120:return "rise"
		if player.velocity.y > 120:return "fall"
		return "apex"
	if lock_time>0 and lock_state=="land":return "land"
	if absf(player.velocity.x)>player.max_speed*.85:return "sprint"
	if absf(player.velocity.x)>35:return "run"
	return "idle"

func _select(state:String)->void:
	visual_state=state
	var animation:String="air_roll" if state=="somersault" else state
	var speed:float=1
	if state in ["run","sprint"]:speed=clampf(.65+absf(player.velocity.x)/player.max_speed*.55,.65,1.3)
	if current_animation!=animation:
		current_animation=animation;sprite.speed_scale=speed;sprite.play(animation)
	else:sprite.speed_scale=speed

func _update_facing()->void:
	if visual_state=="wall_slide":facing=-player._wall_contact_side
	elif visual_state=="wall_jump":facing=wall_jump_facing
	elif absf(player.velocity.x)>35:facing=int(signf(player.velocity.x))
	elif visual_state not in ["somersault","land"]:facing=player.face_direction
	if facing==0:facing=1
	facing_root.scale=Vector2(facing,1)
	# The template's unflipped contact hand reaches left. This offsets only art.
	facing_root.position.x=player._wall_contact_side*wall_contact_offset if visual_state=="wall_slide" else 0

func _can_somersault(grounded:bool)->bool:
	if not allow_somersaults or not flourish_eligible or somersault_used or somersault_active or grounded or player.is_dead:return false
	if spawn_time>0 or air_time<somersault_air_delay or player.is_sliding or player.is_wall_jumping:return false
	if player._wall_contact_side!=0 or player.velocity.y>650:return false
	if takeoff_speed<somersault_min_speed and takeoff_kind!="spring":return false
	var space:=player.get_world_2d().direct_space_state
	for side in [-1,1]:
		var from:=player.global_position+Vector2(0,-4)
		var query:=PhysicsRayQueryParameters2D.create(from,from+Vector2(side*somersault_wall_clearance,0),2,[player.get_rid()])
		if not space.intersect_ray(query).is_empty():return false
	return true

func _pulse(value:Vector2,recovery:float)->void:
	if squash_tween and squash_tween.is_valid():squash_tween.kill()
	squash_root.scale=value
	squash_tween=create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	squash_tween.tween_property(squash_root,"scale",Vector2.ONE,recovery).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _reset_transforms()->void:
	if squash_tween and squash_tween.is_valid():squash_tween.kill()
	squash_root.scale=Vector2.ONE;rotation=0
	facing_root.position=Vector2.ZERO;facing_root.scale=Vector2.ONE
	modulate=Color.WHITE

func _on_player_jumped(from_wall:bool)->void:
	if player.is_dead:return
	takeoff_speed=absf(player.velocity.x)
	# Decide at takeoff; a cooldown expiring mid-jump cannot cause a late spin.
	flourish_eligible=flourish_wait<=0
	if from_wall:wall_jump_facing=int(signf(player.velocity.x))
	takeoff_kind="wall" if from_wall else "spring" if player._spring_launch else "jump"
	lock_state="wall_jump" if from_wall else "spring_launch" if player._spring_launch else "takeoff"
	lock_time=.10 if from_wall else .12 if player._spring_launch else .075
	somersault_active=false;_select(lock_state);_update_facing()
	_pulse(jump_stretch,.085)
	jump_fx_count+=1
	jump_sfx.pitch_scale=1.2 if from_wall else .95 if player._spring_launch else 1.0
	jump_sfx.play()
	jump_particles.position=Vector2(-signf(player.velocity.x)*13,-4) if from_wall else Vector2(0,8)
	jump_particles.amount=12 if player._spring_launch else 8;jump_particles.restart()

func _land(speed:float)->void:
	landing_fx_count+=1;lock_state="land";lock_time=.11
	_pulse(Vector2(1.16,.82) if speed>800 else land_squash,.13)
	land_sfx.pitch_scale=clampf(.9+speed/2500,.9,1.2);land_sfx.play()
	land_particles.amount=12 if speed>800 else 8;land_particles.restart()

func _on_player_died()->void:
	_reset_transforms();somersault_active=false;lock_time=0;spawn_time=0;death_time=0
	_select("death");_stop_continuous_fx();_clear_trails()
	death_sfx.play();death_particles.restart()

func _on_player_respawned()->void:
	_reset_transforms();show();sprite.show()
	lock_time=0;lock_state="";death_time=0;spawn_time=.12;facing=1;wall_jump_facing=1
	somersault_active=false;somersault_used=false;air_time=0;takeoff_speed=0
	flourish_wait=0;flourish_eligible=false
	previous_velocity=Vector2.ZERO;previous_grounded=false;footstep_cooldown=0
	_stop_continuous_fx();_clear_trails();_select("respawn")
	_pulse(Vector2(.94,1.06),.10)
	spawn_sfx.play();spawn_particles.restart()

func _on_animation_finished()->void:
	if sprite.animation==&"air_roll" and visual_state=="somersault":somersault_active=false

func _on_frame_changed()->void:
	if visual_state in ["run","sprint"] and sprite.frame in [0,3] and player.is_on_floor() and not player.is_dead and footstep_cooldown<=0:
		footstep_sfx.pitch_scale=1.0 if visual_state=="run" else 1.08
		footstep_sfx.play();footstep_cooldown=.09

func _stop_continuous_fx()->void:
	run_particles.emitting=false;wall_particles.emitting=false
	wall_slide_sfx.stop()

func _update_continuous_fx(delta:float,grounded:bool)->void:
	run_particles.emitting=grounded and visual_state in ["run","sprint"]
	run_particles.direction=Vector2(-signf(player.velocity.x),0)
	wall_particles.emitting=visual_state=="wall_slide"
	if wall_particles.emitting:
		wall_particles.position=Vector2(player._wall_contact_side*13,-10)
		wall_particles.direction=Vector2(-player._wall_contact_side,1)
		if not wall_slide_sfx.playing:wall_slide_sfx.play()
	elif wall_slide_sfx.playing:wall_slide_sfx.stop()
	trail_clock+=delta
	if trail_clock>=.025:
		trail_clock=0
		_update_trail(roll_trail,somersault_active)
		_update_trail(speed_trail,absf(player.velocity.x)>480 and visual_state in ["run","sprint","spring_launch"])

func _update_trail(trail:Line2D,active:bool)->void:
	if active:
		trail.add_point(player.global_position+Vector2(0,-6))
		while trail.get_point_count()>7:trail.remove_point(0)
	elif trail.get_point_count()>0:trail.remove_point(0)
	trail.visible=trail.get_point_count()>1

func _clear_trails()->void:
	for trail in [roll_trail,speed_trail]:trail.clear_points();trail.hide()

func set_cube_fallback(value:bool)->void:
	debug_cube=value;_apply_visual_mode()

func _apply_visual_mode()->void:
	sprite.visible=not debug_cube;cube.visible=debug_cube

func _update_debug()->void:
	debug_label.visible=show_visual_debug
	if not show_visual_debug:return
	debug_label.text="%s / %s [%d]\nvx %.0f  vy %.0f\nsquash %s  roll %s"%[visual_state,current_animation,sprite.frame,player.velocity.x,player.velocity.y,str(not squash_root.scale.is_equal_approx(Vector2.ONE)),str(somersault_active)]

func _unhandled_key_input(event:InputEvent)->void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_F7:show_visual_debug=not show_visual_debug
		if event.keycode==KEY_F8:set_cube_fallback(not debug_cube)
