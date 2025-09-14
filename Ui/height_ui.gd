# HeightUI.gd
extends Control

@onready var height_label: Label = $VBoxContainer/HeightLabel
@onready var max_height_label: Label = $VBoxContainer/MaxHeightLabel

func _ready():
	# Position in top right
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	
	# Connect to height tracker signals
	HeightTracker.height_changed.connect(_on_height_changed)
	HeightTracker.max_height_changed.connect(_on_max_height_changed)
	
	# Initial display
	_on_height_changed(0.0)
	_on_max_height_changed(0.0)

func _on_height_changed(height: float):
	height_label.text = "Height: %.1f m" % height

func _on_max_height_changed(max_height: float):
	max_height_label.text = "Max: %.1f m" % max_height
