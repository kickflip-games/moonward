@tool
extends Node2D

## Script controlling a moving platform (or spike, or anything else you might want to move).
## Works both in editor (preview/debug) and in builds.

@export var move_to := Vector2(0, -128) : set = set_move_to
func set_move_to(new_value: Vector2) -> void:
	move_to = new_value
	# Only snap child positions instantly when editing in the editor
	if Engine.is_editor_hint() and get_child_count() > 0:
		for child in get_children():
			child.position = move_to

@export var speed: int = 64 
@export var delay: float = 0.4 ## delay (sec) before moving to move_to
@export var line_width : float = 4.0

func _ready() -> void:
	set_move_to(move_to)

	# Always start tweens, both in editor and in game
	for child in get_children():
		start_tween(child)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if line_width == 0:
		return
	draw_line(move_to, -move_to, Color.WHITE, line_width)

func start_tween(moved: Node2D) -> void:
	moved.position = move_to
	if speed == 0:
		return
	var time = move_to.length() / float(speed)
	var tween: Tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(moved, "position", -move_to, time).set_delay(delay)
	tween.tween_property(moved, "position", move_to, time).set_delay(delay)
	tween.set_loops()
