extends Node

func _ready() -> void:
	var result: TileSet = preload("res://Art/Cavern/terrain_factory.gd").build()
	var error := ResourceSaver.save(result, "res://Art/Cavern/cavern_tileset.tres")
	if error != OK:
		push_error("Could not save cavern terrain resource: %s" % error_string(error))
	get_tree().quit(0 if error == OK else 1)
