@tool
extends Area2D
@export var size := Vector2(160, 240)
@export var force := 3400.0
var time := 0.0

func _physics_process(delta: float) -> void:
	if not Engine.is_editor_hint():
		time += delta
		for body in get_overlapping_bodies():
			if body is Player and not body.is_dead and not body.is_on_floor():
				body.velocity.x = clampf(body.velocity.x + force * delta, -740, 740)
	queue_redraw()

func _draw() -> void:
	var direction := signf(force)
	for y in range(24, int(size.y), 48):
		var x := fposmod(time * direction * 90, size.x - 48) - size.x / 2 + 24
		var at := Vector2(x, y - size.y / 2)
		draw_line(at, at + Vector2(direction * 32, 0), Color(.5, .72, .84, .45), 2)
		draw_line(at + Vector2(direction * 32, 0), at + Vector2(direction * 24, -5), Color(.5, .72, .84, .45), 2)
