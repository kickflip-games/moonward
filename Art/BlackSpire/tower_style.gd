@tool
extends Node2D
const TERRAIN=preload("res://Art/BlackSpire/tower_terrain.gd")
const SURFACE=preload("res://Art/BlackSpire/surface_material.gd")
const BACKGROUND=preload("res://Art/BlackSpire/background.gd")
const ROTOR=preload("res://Art/BlackSpire/rotor_art.gd")
const SUPPORT=preload("res://Art/BlackSpire/platform_support.gd")
# Compatibility inspector fields for older scenes; BlackSpire is the active art.
@export var terrain_style:int=0
@export var terrain_brightness:float=1.0
var refreshing:=false
func _ready()->void:
	apply_visuals()
	if Engine.is_editor_hint() and not $GameLayer.changed.is_connected(refresh):
		$GameLayer.changed.connect(refresh)
func refresh()->void:
	if refreshing:return
	refreshing=true
	apply_visuals.call_deferred()
func prop(name:String,at:Vector2,scale_value:float=2,behind:bool=true)->Sprite2D:
	var sprite:=Sprite2D.new();sprite.texture=load("res://Art/BlackSpire/Props/regions/"+name+".tres")
	sprite.position=at;sprite.scale=Vector2.ONE*scale_value;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index=-2 if behind else 2
	$BlackSpireDecorations.add_child(sprite);return sprite
func apply_visuals()->void:
	refreshing=false
	if not is_inside_tree():return
	TERRAIN.apply($GameLayer)
	for name in ["CavernTerrain","BlackSpireDecorations","TowerDepth"]:
		var old:=get_node_or_null(name)
		if old:remove_child(old);old.queue_free()
	var decor:=Node2D.new();decor.name="BlackSpireDecorations";add_child(decor)
	if has_node("Background"):$Background.visible=false
	if not Engine.is_editor_hint():
		var depth:=Node2D.new();depth.set_script(BACKGROUND);depth.name="TowerDepth";add_child(depth)
	for platform in $Platforms.get_children():
		if platform.has_node("ActualPlatform"):
			platform.modulate=Color.WHITE
			platform.show_path=false
			for visual in platform.get_node("ActualPlatform").get_children():
				if visual is Polygon2D:SURFACE.skin(visual,SURFACE.PLANKS)
			if not Engine.is_editor_hint():
				var support:=Node2D.new();support.set_script(SUPPORT);support.body=platform.get_node("ActualPlatform")
				support.position=platform.position+$Platforms.position;support.anchor=Vector2(platform.move_to.x,minf(platform.move_to.y,-platform.move_to.y)-55)
				support.z_index=-1;decor.add_child(support)
		elif platform.has_node("DetectionArea"):
			SURFACE.skin(platform.get_node("Sprite2D"),SURFACE.FRAGILE_PLANKS)
			platform.get_node("Background").modulate=Color(.45,.35,.6,.5)
		elif platform.has_node("Sprite/Circle"):
			platform.get_node("Sprite/Circle").hide()
			if not platform.has_node("Sprite/NativeRotor"):
				var art:=Node2D.new();art.set_script(ROTOR);platform.get_node("Sprite").add_child(art)
			for visual in platform.get_node("Sprite").get_children():
				if visual is Polygon2D:SURFACE.skin(visual,SURFACE.STONE)
	for visual in $Spikes.find_children("*","Node2D",true,false):
		visual.modulate=Color.WHITE
		if visual.has_node("ActualPlatform"):visual.show_path=false
		if visual is Triangle:SURFACE.skin(visual,SURFACE.SPIKE,true)
		elif visual is Rectangle or visual is Polygon2D:SURFACE.skin(visual,SURFACE.STONE,true)
	for turret in $Turrets.get_children():
		for visual in turret.get_node("Sprite").get_children():
			if visual is Rectangle:SURFACE.skin(visual,SURFACE.METAL)
			elif visual is Circle:SURFACE.skin(visual,SURFACE.STONE)
	for checkpoint in $Checkpoints.get_children():
		checkpoint.get_node("FIRE").amount=8
		var at:Vector2=checkpoint.position+$Checkpoints.position
		var arch:=prop("arch",at+Vector2(-7,-56),2);arch.modulate=Color(.5,.5,.7)
		if checkpoint.progression_index%2==0:
			var pillar:=prop("pillar_short",at+Vector2(-105,-28));pillar.modulate=Color(.5,.5,.7)
			prop("barrel",at+Vector2(112,-26))
	# Sparse windows belong inside sufficiently thick solid wall regions.
	var occupied:Dictionary={}
	for cell in $GameLayer.get_used_cells():
		if $GameLayer.get_cell_atlas_coords(cell)==Vector2i(1,1):occupied[cell]=true
	var bands:Dictionary={}
	for cell in occupied:
		var centre:Vector2=$GameLayer.transform*Vector2($GameLayer.map_to_local(cell))
		var band:=int(floor(centre.y/512))
		if bands.has(band):continue
		var supported:=true
		for dx in range(-1,2):
			for dy in range(-2,3):
				if not occupied.has(cell+Vector2i(dx,dy)):supported=false
		if supported:
			bands[band]=true
			var window:=prop("window",centre,2,false);window.modulate=Color(.45,.5,.72,.85)
	# The entrance gate is a deliberate landmark, rather than repeated wall decoration.
	prop("door_open",Vector2(-1269,712),2).modulate=Color(.56,.56,.75)
	prop("torch",Vector2(-1430,725))
	prop("torch",Vector2(-1110,725))
	if has_node("Ui"):
		$Ui/GameTitle.theme=null;$Ui/GameTitle.bbcode_enabled=false;$Ui/GameTitle.text="MOONWARD"
		$Ui/GameTitle.add_theme_font_size_override("normal_font_size",28)
		$Ui/GameTitle.position=Vector2(-1429,584);$Ui/GameTitle.size=Vector2(320,48);$Ui/GameTitle.modulate=Color(.65,.7,.85)
		$Ui/Instructions.theme=null;$Ui/Instructions.text="Climb toward the moon";$Ui/Instructions.add_theme_font_size_override("font_size",16)
		$Ui/Instructions.position=Vector2(-1399,620);$Ui/Instructions.size=Vector2(260,32);$Ui/Instructions.modulate=Color(.56,.6,.74)
		$Ui/Checkpoint.hide()
		$Ui/EndGame.theme=null;$Ui/EndGame.bbcode_enabled=false;$Ui/EndGame.text="THE MOONWARD SUMMIT"
		$Ui/EndGame.add_theme_font_size_override("normal_font_size",26)
	if has_node("SnowParticles"):$SnowParticles.modulate=Color(.4,.44,.65,.18)
	if has_node("Moon"):$Moon.modulate=Color(.7,.78,.92)
