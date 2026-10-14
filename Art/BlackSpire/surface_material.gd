extends RefCounted
const SHEET=preload("res://Art/BlackSpire/Source/Medieval_tiles_free_2.0.png")
const PROPS=preload("res://Art/BlackSpire/Source/Medieval_props_free.png")
const SHADER=preload("res://Art/BlackSpire/surface.gdshader")
const STONE=Rect2(640,400,24,16)
const METAL=Rect2(53,112,12,24)
const PLANKS=Rect2(414,67,26,18)
const FRAGILE_PLANKS=Rect2(736,304,48,10)
const SPIKE=Rect2(546,440,14,8)
static func skin(node: CanvasItem, region: Rect2, dangerous: bool=false) -> void:
	var bounds:=Rect2()
	if node is Polygon2D:
		if node.polygon.is_empty():return
		bounds=Rect2(node.polygon[0],Vector2.ZERO)
		for point in node.polygon:bounds=bounds.expand(point)
	elif node is Triangle:
		var h:float=node.side*sqrt(3.0)/2
		bounds=Rect2(Vector2(-node.side/2,-2*h/3),Vector2(node.side,h))
	elif node is Rectangle:bounds=Rect2(Vector2(-node.width,-node.height)/2,Vector2(node.width,node.height))
	elif node is Circle:bounds=Rect2(Vector2(-node.radius,-node.radius),Vector2.ONE*node.radius*2)
	elif node is Sprite2D:bounds=node.get_rect()
	else:return
	var material:=ShaderMaterial.new();material.shader=SHADER
	material.set_shader_parameter("sheet",PROPS if region==PLANKS else SHEET)
	material.set_shader_parameter("region",Vector4(region.position.x,region.position.y,region.size.x,region.size.y))
	material.set_shader_parameter("bounds",Vector4(bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y))
	material.set_shader_parameter("dangerous",dangerous)
	node.material=material;node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	if node is Polygon2D or node is Triangle or node is Rectangle or node is Circle:node.color=Color.WHITE
