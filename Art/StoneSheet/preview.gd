extends "res://Art/Cavern/preview.gd"

const STONE_TILESET = preload("res://Art/StoneSheet/stone_tileset.tres")
var entries: Array = []

func terrain_tileset() -> TileSet:
	return STONE_TILESET

func load_inventory() -> void:
	entries = JSON.parse_string(FileAccess.get_file_as_string("res://Art/StoneSheet/catalog.json"))["entries"]
	for entry in entries:
		textures.append(load(entry["texture"]))

func inventory_caption(index: int) -> String:
	return entries[index]["name"]
