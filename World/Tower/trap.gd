@tool
extends Area2D

## Phase offsets stagger traps. Every burst/press has a visible warning and rest.
@export_enum("spikes", "crusher", "dart", "flame", "pendulum", "saw") var kind := "spikes"
@export var size := Vector2(64, 24)
@export var travel := Vector2.ZERO
@export var period := 4.8
@export var phase := 0.0
@export var warning_time := 0.75
var home := Vector2.ZERO
var elapsed := 0.0
var armed := false
var warning := false
var progress := 0.0
const METAL = preload("res://Art/BlackSpire/Source/Medieval_tiles_free_2.0.png")

func _ready() -> void:
	home = position
	if not Engine.is_editor_hint():
		body_entered.connect(_touch)
		reset_cycle()

func reset_cycle() -> void:
	elapsed = 0
	position = home
	armed = kind == "spikes"
	warning = false
	_update_collision()

func _touch(body: Node) -> void:
	if armed and body is Player:
		body.die()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	elapsed += delta
	var t := fposmod(elapsed + phase, period)
	warning = false
	armed = kind == "spikes"
	position = home
	progress = t / period
	match kind:
		"crusher":
			warning = t >= 1.0 and t < 1.0 + warning_time
			var drop := 1.0 + warning_time
			armed = t >= drop and t < drop + 0.8
			var amount := clampf((t - drop) / 0.4, 0, 1)
			if t >= drop + 0.8:
				amount = 1.0 - clampf((t - drop - 0.8) / 0.9, 0, 1)
			position += travel * amount
		"dart":
			warning = t < warning_time
			armed = t >= warning_time and t < warning_time + 1.2
			position += travel * clampf((t - warning_time) / 1.2, 0, 1) if armed else Vector2.ZERO
		"flame":
			warning = t >= 0.8 and t < 0.8 + warning_time
			armed = t >= 0.8 + warning_time and t < 0.8 + warning_time + 1.0
		"pendulum":
			armed = true
			position += Vector2(travel.x * sin(TAU * progress), travel.y * (1.0 - cos(TAU * progress)) * 0.3)
		"saw":
			armed = true
			position += travel * sin(TAU * progress)
	_update_collision()
	if armed:
		for body in get_overlapping_bodies():
			_touch(body)
	queue_redraw()

func _update_collision() -> void:
	# A dormant trap is also absent from the player's HurtArea mask.
	set_deferred("collision_layer", 4 if armed else 0)

func _draw() -> void:
	var live := armed or Engine.is_editor_hint()
	var danger := Color("ed986c")
	var tell := Color("f5ca79")
	var color := tell if warning else danger if live else Color("5e5268")
	var rect := Rect2(-size / 2, size)
	match kind:
		"spikes":
			for i in maxi(1, int(size.x / 24)):
				var left := -size.x / 2 + i * 24
				draw_colored_polygon(PackedVector2Array([Vector2(left, size.y / 2), Vector2(left + 12, -size.y / 2), Vector2(left + 24, size.y / 2)]), danger)
		"crusher":
			draw_texture_rect_region(METAL, rect, Rect2(53, 112, 12, 24))
			draw_rect(rect, color, false, 3)
			for i in maxi(1, int(size.x / 24)):
				var x := -size.x / 2 + i * 24
				draw_colored_polygon(PackedVector2Array([Vector2(x, size.y / 2 - 10), Vector2(x + 12, size.y / 2), Vector2(x + 24, size.y / 2 - 10)]), color)
		"saw", "pendulum":
			var radius := size.x / 2
			var points := PackedVector2Array()
			for i in 32:
				points.append(Vector2.from_angle(i * TAU / 32 + elapsed * 3) * radius * (1.0 if i % 2 == 0 else 0.72))
			draw_colored_polygon(points, danger)
			draw_circle(Vector2.ZERO, radius * 0.42, Color("40384c"))
			draw_circle(Vector2.ZERO, 4, tell)
		"flame":
			if live:
				for i in 3:
					var x := (i - 1) * size.x / 3
					draw_colored_polygon(PackedVector2Array([Vector2(x - 10, size.y / 2), Vector2(x, -size.y / 2), Vector2(x + 10, size.y / 2)]), danger)
			else:
				draw_rect(Rect2(-size.x / 2, size.y / 2 - 8, size.x, 8), color)
		"dart":
			if live:
				var direction := signf(travel.x)
				draw_line(Vector2(-direction * 12, 0), Vector2(direction * 12, 0), danger, 4)
				draw_colored_polygon(PackedVector2Array([Vector2(direction * 18, 0), Vector2(direction * 6, -6), Vector2(direction * 6, 6)]), danger)
			else:
				draw_rect(Rect2(-12, -12, 24, 24), color, false, 3)
	if warning:
		draw_circle(Vector2(0, -size.y / 2 - 14), 5 + sin(elapsed * 18) * 2, tell)
