# CheckpointManager.gd (AutoLoad singleton)
extends Node

var checkpoints: Array[Checkpoint] = []
var current_checkpoint_index: int = -1
var player: Player

func _ready():
	# Connect to input for debug functionality
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if event.is_action_pressed("debug_next_checkpoint"): # Map "\" key to this action
		skip_to_next_unvisited_checkpoint()

func register_checkpoint(checkpoint: Checkpoint):
	checkpoints.append(checkpoint)
	# Sort by position or scene order if needed
	checkpoints.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)

func set_player(player_node: Player):
	player = player_node

func checkpoint_activated(checkpoint: Checkpoint):
	var index = checkpoints.find(checkpoint)
	if index > current_checkpoint_index:
		current_checkpoint_index = index

func skip_to_next_unvisited_checkpoint():
	if not player:
		print("No player reference set!")
		return
	
	if checkpoints.is_empty():
		print("No checkpoints registered!")
		return
	
	var next_index = (current_checkpoint_index + 1) % checkpoints.size()
	var next_checkpoint = checkpoints[next_index]
	
	player.global_position = next_checkpoint.global_position
	# Optionally activate the checkpoint too
	next_checkpoint.activate_flag()
	next_checkpoint.activated = true
	current_checkpoint_index = next_index
	
	print("Skipped to checkpoint ", next_index, " (", next_index + 1, "/", checkpoints.size(), ")")
