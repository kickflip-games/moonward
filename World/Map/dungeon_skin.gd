@tool
extends Node2D

## Visual replacement only: existing tiles, surfaces, paths and collision shapes stay authoritative.
const SURFACE = preload("res://Art/Dungeon/surface_material.gd")
const TERRAIN_SHADER = preload("res://Art/Dungeon/terrain.gdshader")

func _ready() -> void:
	var layer: TileMapLayer = $GameLayer
	var terrain := ShaderMaterial.new()
	terrain.shader = TERRAIN_SHADER
	terrain.set_shader_parameter("sheet", SURFACE.SHEET)
	layer.material = terrain
	layer.use_parent_material = false
	layer.modulate = Color.WHITE
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for platform in $Platforms.get_children():
		if platform.has_node("ActualPlatform"):
			platform.modulate = Color.WHITE
			for visual in platform.get_node("ActualPlatform").get_children():
				if visual is Polygon2D:
					SURFACE.skin(visual, SURFACE.PLANKS)
		elif platform.has_node("DetectionArea"):
			SURFACE.skin(platform.get_node("Sprite2D"), SURFACE.FRAGILE_PLANKS)
		elif platform.has_node("Sprite/Circle"):
			for visual in platform.get_node("Sprite").get_children():
				visual.modulate = Color.WHITE
				SURFACE.skin(visual, SURFACE.STONE if visual is Sprite2D else SURFACE.PLANKS)
	for visual in $Spikes.find_children("*", "Node2D", true, false):
		if visual is Triangle:
			SURFACE.skin(visual, SURFACE.SPIKE, true)
		elif visual is Rectangle or visual is Polygon2D:
			SURFACE.skin(visual, SURFACE.STONE, true)
	for turret in $Turrets.get_children():
		for visual in turret.get_node("Sprite").get_children():
			if visual is Rectangle:
				SURFACE.skin(visual, SURFACE.METAL)
			elif visual is Circle:
				SURFACE.skin(visual, SURFACE.STONE)
