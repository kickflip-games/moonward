# CheckpointManager.gd (AutoLoad singleton)
extends Node

var checkpoints: Array[Checkpoint] = []
var current_checkpoint_index: int = -1
var player: Player

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().connect("scene_changed", Callable(self, "_on_scene_changed"))

func _on_scene_changed(new_scene: Node):
	# Reset everything
	checkpoints.clear()
	current_checkpoint_index = -1
	player = null

	# Try to auto-find the player
	_find_player(new_scene)

func _find_player(root: Node):
	# First, try by name
	var candidate = root.get_node_or_null("Player")
	if candidate and candidate is Player:
		set_player(candidate)
		return

	# Otherwise, look through children for a Player instance
	for child in root.get_children():
		if child is Player:
			set_player(child)
			return

	# Couldn’t find player
	print("CheckpointManager: No player found in scene")

func set_player(player_node: Player):
	player = player_node
	print("CheckpointManager: Player set ->", player)

func _input(event):
	if event.is_action_pressed("debug_next_checkpoint"):
		skip_to_next_unvisited_checkpoint()

func register_checkpoint(checkpoint: Checkpoint):
	# Remove dead references
	checkpoints = checkpoints.filter(func(c): return is_instance_valid(c))
	# Add the new checkpoint
	checkpoints.append(checkpoint)
	# Sort valid ones
	checkpoints.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)

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
	
	# Make sure list has no freed references
	checkpoints = checkpoints.filter(func(c): return is_instance_valid(c))
	if checkpoints.is_empty():
		print("All checkpoint references invalid!")
		return

	var next_index = (current_checkpoint_index + 1) % checkpoints.size()
	var next_checkpoint = checkpoints[next_index]
	
	if not is_instance_valid(next_checkpoint):
		print("Checkpoint reference is invalid!")
		return
	
	player.global_position = next_checkpoint.global_position
	next_checkpoint.activate_flag()
	next_checkpoint.activated = true
	current_checkpoint_index = next_index
	
	print("Skipped to checkpoint ", next_index, " (", next_index + 1, "/", checkpoints.size(), ")")
