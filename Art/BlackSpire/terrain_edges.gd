@tool
extends Node2D
const SHEET=preload("res://Art/BlackSpire/Source/Medieval_tiles_free_2.0.png")
var edges: Array=[]
var slopes: Array=[]
var hazards: Array=[]
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
		var rect:=Rect2(688,48,16,16) if at in [1,4] else Rect2(738,16,16,16)
		if at in [3,4]:
			draw_set_transform(area.position+Vector2(0,32),0,Vector2(1,-1))
			draw_texture_rect_region(SHEET,Rect2(0,0,32,32),rect,Color(.88,.88,.94))
			draw_set_transform(Vector2.ZERO)
		else:draw_texture_rect_region(SHEET,area,rect,Color(.88,.88,.94))
	for points in hazards:
		draw_colored_polygon(points,Color("ed986c"))
