extends Control
@export var force_on: bool = false
@onready var left_button: TouchScreenButton = $LeftButton
@onready var right_button: TouchScreenButton = $RightButton
@onready var jump_button: TouchScreenButton = $JumpButton

func _ready():
	if DisplayServer.is_touchscreen_available() or force_on:
		print("Touchscreen")
		visible = true
		setup_mobile_controls()
	else:
		print("No Touchscreen")
		visible = false

func setup_mobile_controls():
	# Connect button signals
	left_button.pressed.connect(_on_left_pressed)
	left_button.released.connect(_on_left_released)
	right_button.pressed.connect(_on_right_pressed)
	right_button.released.connect(_on_right_released)
	jump_button.pressed.connect(_on_jump_pressed)
	jump_button.released.connect(_on_jump_released)

# Left button handlers
func _on_left_pressed():
	Input.action_press("ui_left")

func _on_left_released():
	Input.action_release("ui_left")

# Right button handlers
func _on_right_pressed():
	Input.action_press("ui_right")

func _on_right_released():
	Input.action_release("ui_right")

# Jump button handlers
func _on_jump_pressed():
	Input.action_press("jump")

func _on_jump_released():
	Input.action_release("jump")
