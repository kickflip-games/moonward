@tool
extends Node2D
func _draw() -> void:
	draw_circle(Vector2.ZERO,128,Color("252241"))
	draw_arc(Vector2.ZERO,124,0,TAU,96,Color("824737"),6)
	draw_arc(Vector2.ZERO,111,0,TAU,96,Color("433067"),4)
	for i in 8:
		var p:=Vector2.from_angle(i*TAU/8)*116
		draw_rect(Rect2(p-Vector2.ONE*3,Vector2.ONE*6),Color("a46dc0"))
	draw_circle(Vector2.ZERO,24,Color("433067"))
	draw_circle(Vector2.ZERO,9,Color("709ba7"))
