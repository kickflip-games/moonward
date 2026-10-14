extends Node2D
const SKY=preload("res://Art/BlackSpire/sky.gdshader")
const ARCH=preload("res://Art/BlackSpire/Props/regions/arch.tres")
const WINDOW=preload("res://Art/BlackSpire/Props/regions/window.tres")
const PILLAR=preload("res://Art/BlackSpire/Props/regions/pillar.tres")
@export var centre_x:float=-1200.0
@export var opening_height:float=4000.0
@export var height_span:float=6000.0
var sky_material:ShaderMaterial
var far:Parallax2D
var mid:Parallax2D
func _ready()->void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	var canvas:=CanvasLayer.new();canvas.layer=-20;canvas.name="FarSky";add_child(canvas)
	var rect:=ColorRect.new();rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky_material=ShaderMaterial.new();sky_material.shader=SKY;rect.material=sky_material;canvas.add_child(rect)
	far=Parallax2D.new();far.name="FarArchitecture";far.scroll_scale=Vector2(.22,.22);far.z_index=-15;add_child(far)
	mid=Parallax2D.new();mid.name="MidArchitecture";mid.scroll_scale=Vector2(.6,.6);mid.z_index=-10;add_child(mid)
	for band in range(-8,3):
		for x in [-630.0,-210.0,210.0,630.0]:
			var sprite:=Sprite2D.new();sprite.texture=ARCH;sprite.scale=Vector2.ONE*6
			sprite.position=Vector2(centre_x*.22+x,band*420);sprite.modulate=Color(.24,.24,.38,.55)
			sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;far.add_child(sprite)
	for band in range(-14,3):
		for x in [-550.0,550.0]:
			var sprite:=Sprite2D.new();sprite.texture=PILLAR;sprite.scale=Vector2.ONE*7
			sprite.position=Vector2(centre_x*.6+x,band*500);sprite.modulate=Color(.24,.24,.4,.6)
			sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;mid.add_child(sprite)
		if band%3==0:
			var window:=Sprite2D.new();window.texture=WINDOW;window.scale=Vector2.ONE*3
			window.position=Vector2(centre_x*.6,band*500-140);window.modulate=Color(.3,.32,.48,.45)
			window.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;mid.add_child(window)

func _process(_delta:float)->void:
	var camera:=get_viewport().get_camera_2d()
	if not camera:return
	var openness:=clampf((-camera.global_position.y-opening_height)/height_span,0,1)
	sky_material.set_shader_parameter("openness",openness)
	far.modulate.a=1-openness*.55;mid.modulate.a=1-openness*.82
