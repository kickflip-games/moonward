@tool
extends Node2D
const SHEET=preload("res://Art/BlackSpire/Source/Medieval_tiles_free_2.0.png")
var edges: Array=[]
var slopes: Array=[]
var hazards: Array=[]
static func slope_draw_transform(area:Rect2,shape:int)->Transform2D:
	# Reverse both axes for ceilings, keeping the original diagonal's gradient.
	return Transform2D(Vector2(-1,0),Vector2(0,-1),area.end) if shape in [3,4] else Transform2D(0,area.position)
func _draw() -> void:
	for segment in edges:
		var a:Vector2=segment[0];var b:Vector2=segment[1]
		var delta:=b-a;var length:=delta.length()
		var direction:=delta.normalized()
		# Top/floor cap art at original density. The shallow band keeps 32px shafts readable.
		var offset:=0.0
		while offset<length-0.01:
			var width:=minf(24,(length-offset)/2)
			draw_set_transform(a+direction*offset,delta.angle(),Vector2.ONE*2)
			draw_texture_rect_region(SHEET,Rect2(0,0,width,6),Rect2(65,101,width,6),Color(0.88,0.88,0.94))
			offset+=width*2
	draw_set_transform(Vector2.ZERO)
	for item in slopes:
		var area:Rect2=item[0];var at:int=item[1]
		var rect:=Rect2(688,48,16,16) if at in [1,4] else Rect2(736,16,16,16)
		draw_set_transform_matrix(slope_draw_transform(area,at))
		draw_texture_rect_region(SHEET,Rect2(Vector2.ZERO,area.size),rect,Color(.88,.88,.94))
		draw_set_transform(Vector2.ZERO)
	for points in hazards:
		draw_colored_polygon(points,Color("ed986c"))
