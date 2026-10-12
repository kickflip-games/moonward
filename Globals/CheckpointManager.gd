extends Node

var checkpoints: Array[Checkpoint] = []
var current_checkpoint_index: int = -1
var current_checkpoint: Checkpoint
var player: Player

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().scene_changed.connect(_on_scene_changed)

func _on_scene_changed() -> void:
	# Children register before scene_changed; keep the fresh registrations.
	_prune_and_sort()
	var candidates = get_tree().get_nodes_in_group("Player")
	if not candidates.is_empty():
		set_player(candidates[0])
	else:
		player = null
		current_checkpoint = null
		current_checkpoint_index = -1

func set_player(player_node: Player) -> void:
	if player != player_node:
		current_checkpoint = null
		current_checkpoint_index = -1
	player = player_node
	_prune_and_sort()

func _input(event: InputEvent) -> void:
	if OS.is_debug_build() and event.is_action_pressed("debug_next_checkpoint"):
		skip_to_next_unvisited_checkpoint()

func _prune_and_sort() -> void:
	checkpoints = checkpoints.filter(func(c): return is_instance_valid(c) and c.is_inside_tree())
	checkpoints.sort_custom(func(a, b):
		if (a.progression_index >= 0) != (b.progression_index >= 0):
			return a.progression_index >= 0
		if a.progression_index >= 0 and b.progression_index >= 0 and a.progression_index != b.progression_index:
			return a.progression_index < b.progression_index
		if not is_equal_approx(a.global_position.y, b.global_position.y):
			return a.global_position.y > b.global_position.y
		return str(a.get_path()) < str(b.get_path()))
	current_checkpoint_index = checkpoints.find(current_checkpoint) if is_instance_valid(current_checkpoint) else -1

func register_checkpoint(checkpoint: Checkpoint) -> void:
	if not checkpoints.has(checkpoint):
		checkpoints.append(checkpoint)
	_prune_and_sort()

func checkpoint_activated(checkpoint: Checkpoint) -> bool:
	_prune_and_sort()
	var index := checkpoints.find(checkpoint)
	if index < 0 or index <= current_checkpoint_index or not is_instance_valid(player):
		return false
	current_checkpoint = checkpoint
	current_checkpoint_index = index
	player.update_respawn_position(checkpoint.global_position)
	return true

func skip_to_next_unvisited_checkpoint() -> void:
	_prune_and_sort()
	if not is_instance_valid(player) or checkpoints.is_empty():
		return
	var index := current_checkpoint_index + 1
	if index >= checkpoints.size():
		return
	var checkpoint := checkpoints[index]
	checkpoint.activate_for(player)
	player.respawn()
