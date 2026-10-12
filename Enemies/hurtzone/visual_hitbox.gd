extends Hurtzone

## Composite moving hazards: inset each visible primitive instead of a broad box.
func _ready() -> void:
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			remove_child(child)
			child.queue_free()
	for visual in get_parent().get_children():
		var points := PackedVector2Array()
		if visual is Triangle:
			var h: float = visual.side * sqrt(3.0) / 2.0
			points = PackedVector2Array([Vector2(0, -2.0 * h / 3.0),
				Vector2(-visual.side / 2.0, h / 3.0), Vector2(visual.side / 2.0, h / 3.0)])
		elif visual is Rectangle:
			var half := Vector2(visual.width, visual.height) / 2.0
			points = PackedVector2Array([-half, Vector2(half.x, -half.y),
				half, Vector2(-half.x, half.y)])
		if not points.is_empty():
			var collider := CollisionPolygon2D.new()
			for i in points.size():
				points[i] = to_local(visual.to_global(points[i] * 0.88))
			collider.polygon = points
			add_child(collider)
	super._ready()
