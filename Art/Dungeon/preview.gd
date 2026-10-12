extends Control

## Run this scene to browse the optional art. It does not load or alter the tower.
func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("171c29")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	var title := Label.new()
	title.text = "DUNGEON SHEET  •  reusable art preview"
	title.add_theme_font_size_override("font_size", 24)
	layout.add_child(title)
	var description := Label.new()
	description.text = "Original transparent image • nearest filtering • visual tiles only • scroll to browse"
	layout.add_child(description)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(tabs)
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://Art/Dungeon/catalog.json"))
	var groups := {}
	for entry in catalog.entries:
		if not groups.has(entry.category):
			var scroll := ScrollContainer.new()
			scroll.name = entry.category
			scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			tabs.add_child(scroll)
			var grid := GridContainer.new()
			grid.columns = 5
			grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_theme_constant_override("h_separation", 10)
			grid.add_theme_constant_override("v_separation", 10)
			scroll.add_child(grid)
			groups[entry.category] = grid
		var card := VBoxContainer.new()
		card.custom_minimum_size = Vector2(185, 180)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		groups[entry.category].add_child(card)
		var image := TextureRect.new()
		image.texture = load(entry.texture)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.custom_minimum_size = Vector2(160, 140)
		card.add_child(image)
		var label := Label.new()
		label.text = entry.name.replace("_", " ")
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		card.add_child(label)
		card.tooltip_text = entry.texture
