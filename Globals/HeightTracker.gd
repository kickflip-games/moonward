# HeightTracker.gd (AutoLoad singleton)
extends Node

var player: Node = null
var starting_y: float = 0.0
var current_height: int = 0      # in meters, whole numbers only
var max_height: int = 0          # in meters, whole numbers only

const PIXELS_PER_UNIT: float = 500.0
const METERS_PER_UNIT: float = 15.0

signal height_changed(new_height: int)
signal max_height_changed(new_max: int)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func set_player(player_node: Node):
	player = player_node
	starting_y = player.global_position.y
	current_height = 0
	max_height = 0

	# Emit initial values
	height_changed.emit(current_height)
	max_height_changed.emit(max_height)

func _process(_delta):
	if player:
		update_height()

func update_height():
	var raw_height = (starting_y - player.global_position.y) * METERS_PER_UNIT / PIXELS_PER_UNIT
	var new_height = int(max(raw_height, 0.0))  # clamp + round down to whole meters

	if new_height != current_height:
		current_height = new_height
		height_changed.emit(current_height)
		
		if current_height > max_height:
			max_height = current_height
			max_height_changed.emit(max_height)

func reset_height():
	if player:
		starting_y = player.global_position.y
	current_height = 0
	max_height = 0
	height_changed.emit(current_height)
	max_height_changed.emit(max_height)
