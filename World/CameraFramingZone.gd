@tool
extends Node2D

## One optional room rectangle, used by the existing camera's lookahead controller.
@export var size: Vector2 = Vector2(2000, 650)
@export_range(0.5, 1.0) var zoom: float = 0.8

func _ready() -> void:
	add_to_group("camera_framing_zones")
	if Engine.is_editor_hint():
		queue_redraw()

func contains(point: Vector2) -> bool:
	return Rect2(-size / 2.0, size).has_point(to_local(point))

func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(-size / 2.0, size), Color(1, 0.7, 0.3, 0.5), false, 2.0)
