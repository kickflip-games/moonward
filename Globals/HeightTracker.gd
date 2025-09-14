# HeightTracker.gd (AutoLoad singleton)
extends Node

var player: Player
var starting_y: float = 0.0
var current_height: float = 0.0
var max_height: float = 0.0

signal height_changed(new_height: float)
signal max_height_changed(new_max: float)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func set_player(player_node: Player):
	player = player_node
	starting_y = player.global_position.y
	current_height = 0.0
	max_height = 0.0

func _process(_delta):
	if player:
		update_height()

func update_height():
	var new_height = starting_y - player.global_position.y
	
	if abs(new_height - current_height) > 0.1: # Only update if significant change
		current_height = new_height
		height_changed.emit(current_height)
		
		if current_height > max_height:
			max_height = current_height
			max_height_changed.emit(max_height)

func reset_height():
	starting_y = player.global_position.y
	current_height = 0.0
	max_height = 0.0
	height_changed.emit(current_height)
	max_height_changed.emit(max_height)
