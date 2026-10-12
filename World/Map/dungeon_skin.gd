@tool
extends Node2D

## Visual replacement only: existing tiles, surfaces, paths and collision shapes stay authoritative.
const SURFACE = preload("res://Art/Dungeon/surface_material.gd")
const TERRAIN_SHADER = preload("res://Art/Dungeon/terrain.gdshader")
const CAVERN_TERRAIN = preload("res://Art/Cavern/tower_terrain.gd")

var _terrain_refresh_queued := false

@export_enum("Bare rock", "Green grass", "Purple grass") var terrain_style: int = 1:
	set(value):
		terrain_style = clampi(value, 0, 2)
		if is_node_ready():
			_queue_terrain_refresh()
@export_range(1.0, 2.0, 0.05) var terrain_brightness: float = 1.2:
	set(value):
		terrain_brightness = value
		if is_node_ready():
			_queue_terrain_refresh()

func _ready() -> void:
	var layer: TileMapLayer = $GameLayer
	var terrain := ShaderMaterial.new()
	terrain.shader = TERRAIN_SHADER
	terrain.set_shader_parameter("sheet", SURFACE.SHEET)
	terrain.set_shader_parameter("hide_solid", true)
	layer.material = terrain
	layer.use_parent_material = false
	layer.modulate = Color.WHITE
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	CAVERN_TERRAIN.apply(layer, terrain_style, terrain_brightness)
	if Engine.is_editor_hint() and not layer.changed.is_connected(_queue_terrain_refresh):
		layer.changed.connect(_queue_terrain_refresh)
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

func _queue_terrain_refresh() -> void:
	if not _terrain_refresh_queued:
		_terrain_refresh_queued = true
		_refresh_terrain.call_deferred()

func _refresh_terrain() -> void:
	_terrain_refresh_queued = false
	if is_inside_tree():
		CAVERN_TERRAIN.apply($GameLayer, terrain_style, terrain_brightness)
