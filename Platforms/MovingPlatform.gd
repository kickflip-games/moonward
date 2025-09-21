@tool
extends Node2D

## Config
@export var move_to: Vector2 = Vector2(0, -128) : set = _set_move_to
@export var speed: float = 64.0
@export var delay: float = 0.4
@export var line_width: float = 4.0

@export_group("Editor")
@export var pause_in_editor: bool = true
@export var show_path: bool = true
@export var show_platform_preview: bool = true

@onready var _platform: AnimatableBody2D = $ActualPlatform
var _tween: Tween
var _is_moving: bool = false

func _ready() -> void:
	if not _platform:
		push_error("Missing AnimatableBody2D child!")
		return
	
	# Add to moving platform group automatically
	if not is_in_group("moving_platform"):
		add_to_group("moving_platform")
	
	# Place platform at starting point
	_platform.position = move_to
	
	# Only start movement if not paused in editor
	if not (Engine.is_editor_hint() and pause_in_editor):
		start_tween()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void:
	if not show_path or line_width == 0:
		return
	
	# Draw path line
	draw_line(move_to, -move_to, Color.WHITE, line_width)
	
	# Draw arrows to show direction
	
	# Show platform preview positions in editor
	if Engine.is_editor_hint() and show_platform_preview and _platform:
		var platform_size = Vector2(64, 16)  # Adjust based on your platform size
		
		# Draw platform at both positions
		draw_rect(Rect2(move_to - platform_size/2, platform_size), Color.GREEN, false, 2.0)
		draw_rect(Rect2(-move_to - platform_size/2, platform_size), Color.RED, false, 2.0)



func start_tween() -> void:
	if speed <= 0 or not _platform:
		return
	
	# Stop existing tween
	stop_tween()
	
	var time := move_to.length() / speed
	_tween = get_tree().create_tween()
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.set_loops()
	
	# Forward
	_tween.tween_property(_platform, "position", -move_to, time).set_delay(delay)
	# Backward  
	_tween.tween_property(_platform, "position", move_to, time).set_delay(delay)
	
	_is_moving = true

func stop_tween() -> void:
	if _tween:
		_tween.kill()
		_tween = null
	_is_moving = false

func toggle_movement() -> void:
	if _is_moving:
		stop_tween()
	else:
		start_tween()

# Called when move_to changes in editor
func _set_move_to(new_value: Vector2) -> void:
	move_to = new_value
	if Engine.is_editor_hint():
		queue_redraw()
		# Update platform position if paused
		if pause_in_editor and _platform:
			_platform.position = move_to

# Runtime control functions
func pause_movement() -> void:
	stop_tween()

func resume_movement() -> void:
	if not (Engine.is_editor_hint() and pause_in_editor):
		start_tween()

func reset_to_start() -> void:
	stop_tween()
	if _platform:
		_platform.position = move_to

# Editor plugin helper (if you want to add toolbar buttons)
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if not get_node_or_null("ActualPlatform"):
		warnings.push_back("Missing AnimatableBody2D child named 'ActualPlatform'")
	
	if move_to.length() == 0:
		warnings.push_back("move_to distance is zero - platform won't move")
		
	return warnings
