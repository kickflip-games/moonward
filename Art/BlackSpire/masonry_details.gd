@tool
extends Node2D
const TEXTURE=preload("res://Art/BlackSpire/Terrain/masonry_accents.png")
@export var marks:Array=[]
func _draw()->void:
	for mark in marks:
		draw_texture_rect_region(TEXTURE,Rect2(mark[0]-Vector2(48,24),Vector2(96,48)),Rect2(mark[1]*48,0,48,24),Color(.8,.8,.8))
