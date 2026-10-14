@tool
extends StaticBody2D

## Quiet masonry with the same shallow caps used by the existing tower.
@export var size := Vector2(160, 32):
	set(value):
		size = value
		queue_redraw()
@export var frost := false
const FILL = preload("res://Art/BlackSpire/Terrain/quiet_geometry.png")
const SHEET = preload("res://Art/BlackSpire/Source/Medieval_tiles_free_2.0.png")

func _draw() -> void:
	var tint := Color("b1d3e3") if frost else Color.WHITE
	draw_texture_rect_region(FILL, Rect2(Vector2.ZERO, size), Rect2(0, 0, 16, 16), tint)
	var x := 0.0
	while x < size.x:
		var width := minf(48, size.x - x)
		draw_texture_rect_region(SHEET, Rect2(x, 0, width, 12), Rect2(65, 101, width / 2, 6), tint)
		x += width
	draw_line(Vector2(0, size.y), size, Color("272638"), 3)
	if frost:
		draw_line(Vector2(0, 2), Vector2(size.x, 2), Color("a7d8ee"), 3)
