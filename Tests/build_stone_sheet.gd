extends Node

func _ready() -> void:
	var result: TileSet = preload("res://Art/StoneSheet/terrain_factory.gd").build()
	var error := ResourceSaver.save(result, "res://Art/StoneSheet/stone_tileset.tres")
	if error != OK:
		push_error("Could not save stone TileSet: %s" % error_string(error))
	get_tree().quit(0 if error == OK else 1)
