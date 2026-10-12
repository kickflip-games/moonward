extends RefCounted

const SHEET = preload("res://Art/Dungeon/dungeon_spritesheet.png")
const SHADER = preload("res://Art/Dungeon/surface.gdshader")
const STONE = Rect2(31, 336, 103, 106)
const METAL = Rect2(568, 342, 38, 100)
const PLANKS = Rect2(747, 486, 183, 24)
const FRAGILE_PLANKS = Rect2(748, 545, 182, 25)
const SPIKE = Rect2(37, 815, 32, 47)

static func make(region: Rect2, bounds: Rect2, dangerous: bool = false, mask: bool = false) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("sheet", SHEET)
	material.set_shader_parameter("sprite_region", Vector4(region.position.x, region.position.y, region.size.x, region.size.y))
	material.set_shader_parameter("local_bounds", Vector4(bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y))
	material.set_shader_parameter("dangerous", dangerous)
	material.set_shader_parameter("texture_mask", mask)
	return material

static func skin(node: CanvasItem, region: Rect2, dangerous: bool = false) -> void:
	var bounds := Rect2()
	var mask := false
	if node is Polygon2D:
		if node.polygon.is_empty():
			return
		bounds = Rect2(node.polygon[0], Vector2.ZERO)
		for point in node.polygon:
			bounds = bounds.expand(point)
	elif node is Triangle:
		var height: float = node.side * sqrt(3.0) / 2.0
		bounds = Rect2(Vector2(-node.side / 2.0, -2.0 * height / 3.0), Vector2(node.side, height))
	elif node is Circle:
		bounds = Rect2(Vector2(-node.radius, -node.radius), Vector2(node.radius, node.radius) * 2.0)
	elif node is Rectangle:
		bounds = Rect2(Vector2(-node.width, -node.height) / 2.0, Vector2(node.width, node.height))
	elif node is Sprite2D:
		bounds = node.get_rect()
		mask = true
	else:
		return
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return
	node.material = make(region, bounds, dangerous, mask)
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if node is Polygon2D or node is Triangle or node is Rectangle or node is Circle:
		node.color = Color.WHITE
