@tool
extends Node2D

## Config
@export var move_to: Vector2 = Vector2(0, -128)
@export var speed: float = 64.0
@export var delay: float = 0.4
@export var line_width: float = 4.0

@onready var _platform: AnimatableBody2D = $ActualPlatform

func _ready() -> void:
	if not _platform:
		push_error("Missing AnimatableBody2D child!")
		return

	# Add to moving platform group automatically
	if not is_in_group("moving_platform"):
		add_to_group("moving_platform")

	# Place platform at starting point
	_platform.position = move_to
	start_tween()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void:
	if line_width == 0:
		return
	draw_line(move_to, -move_to, Color.WHITE, line_width)

func start_tween() -> void:
	if speed <= 0:
		return

	var time := move_to.length() / speed
	var tween := get_tree().create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_loops()

	# Forward
	tween.tween_property(_platform, "position", -move_to, time).set_delay(delay)
	# Backward
	tween.tween_property(_platform, "position", move_to, time).set_delay(delay)
