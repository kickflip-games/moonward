extends Control
@onready var height_label:Label=$VBoxContainer/HeightLabel
@onready var max_height_label:Label=$VBoxContainer/MaxHeightLabel
func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	grow_horizontal=Control.GROW_DIRECTION_END
	grow_vertical=Control.GROW_DIRECTION_END
	size=Vector2(240,44);position=Vector2(16,12)
	$VBoxContainer.position=Vector2.ZERO
	height_label.top_level=false;height_label.theme=null
	height_label.add_theme_font_size_override("font_size",16)
	height_label.add_theme_color_override("font_color",Color("bdc6dc"))
	height_label.add_theme_constant_override("outline_size",0)
	height_label.add_theme_constant_override("shadow_outline_size",0)
	height_label.add_theme_constant_override("shadow_offset_y",0)
	HeightTracker.height_changed.connect(_on_height_changed)
	HeightTracker.max_height_changed.connect(_on_max_height_changed)
	_on_height_changed(0);_on_max_height_changed(0)
func _on_height_changed(height:float)->void:
	height_label.text="Height %d m"%int(height)
func _on_max_height_changed(max_height:float)->void:
	max_height_label.text="Best: %.1f m"%max_height
