@tool
extends Node2D
@export var trap_path: NodePath

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var trap := get_node_or_null(trap_path)
	if not trap:
		return
	var at := to_local(trap.global_position)
	var metal := Color("504357")
	if trap.kind in ["crusher", "pendulum"]:
		var anchor := Vector2(0,-200)
		draw_line(anchor, at, metal, 2)
		var distance := anchor.distance_to(at)
		var direction := anchor.direction_to(at)
		for offset in range(8,int(distance),12):
			draw_circle(anchor+direction*offset,3,Color("605468"),false,1)
	elif trap.kind == "dart":
		draw_rect(Rect2(-14,-16,28,32),metal)
		draw_rect(Rect2(-8,-7,16,14),Color("171522"))
	elif trap.kind == "flame":
		draw_rect(Rect2(-trap.size.x/2,trap.size.y/2-8,trap.size.x,16),metal)
	if trap.kind in ["dart", "crusher", "saw"]:
		var path_end: Vector2 = trap.travel
		var length := path_end.length()
		var direction := path_end.normalized()
		var alpha := .45 if trap.warning else .18
		var color := Color(.85,.65,.45,alpha)
		var start := -int(length) if trap.kind == "saw" else 0
		for offset in range(start,int(length),16):
			draw_line(direction*offset,direction*minf(offset+5,length),color,1)
