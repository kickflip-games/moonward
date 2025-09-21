# Again, wht is this used in?

extends Polygon2D

func _ready() -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD   # additive blending
	self.material = mat
