extends "res://Scenes/visual_direction_test.gd"
func _ready()->void:
	super._ready()
	# This independent instance adds two gaps; the actual tower remains untouched.
	var ground:TileMapLayer=$MainTerrain
	for x in [8,15,16,17,18]:
		for y in range(10,30):ground.erase_cell(Vector2i(x,y))
	# Update exposed sides after removing cells, retaining hand-selected slopes.
	var cells:Array[Vector2i]=[]
	var manual:Dictionary={}
	for cell in ground.get_used_cells():
		if ground.get_cell_tile_data(cell).terrain==0:cells.append(cell)
		else:manual[cell]=ground.get_cell_atlas_coords(cell)
	ground.set_cells_terrain_connect(cells,0,0,false)
	for cell in manual:ground.set_cell(cell,0,manual[cell])
	var canvas:=CanvasLayer.new();add_child(canvas)
	var help:=Label.new();help.position=Vector2(16,70)
	help.add_theme_font_size_override("font_size",13)
	help.text="F7 visual debug · F8 cube fallback · R retry · K death test · \\ next checkpoint"
	help.modulate=Color("b4b9d2");canvas.add_child(help)
func _unhandled_key_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_R:$Player.respawn()
		if event.keycode==KEY_K:$Player.die()
