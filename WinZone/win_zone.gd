extends Area2D

@export var win_effect_enabled: bool = true
@export var auto_transition_delay: float = 10.0
@export var endgame_cam:PhantomCamera2D 

signal player_won

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var has_won: bool = false

func _ready():
	# Connect the signal
	body_entered.connect(_on_body_entered)
	
	# Optional: Add to a group for easy finding
	add_to_group("win_zones")
	

func _on_body_entered(body: Node2D):
	if body.is_in_group("Player") and not has_won:
		
		has_won = true
		trigger_win(body)

func trigger_win(player: Node2D):
	print("PLAYER WON!")
	endgame_cam.priority = 10
	player._input_locked = true
	
	# Emit signal for other systems to listen to
	player_won.emit()
	
	# Optional: Disable player movement
	if player.has_method("disable_movement"):
		player.disable_movement()
	
	# Play win effects
	if win_effect_enabled:
		play_win_effects()
	
	# Transition to end game scene
	if auto_transition_delay > 0:
		await get_tree().create_timer(auto_transition_delay).timeout
		transition_to_end_scene()

func play_win_effects():
	# Visual celebration
	pass
	# You can add:
	# - Particle effects
	# - Sound effects
	# - Screen shake
	# - Flash effect

func transition_to_end_scene():
	SceneManager.reload_scene({
		"pattern_enter": "squares",
		"pattern_leave": "squares",
		"invert_on_leave": true,
		"color": Color(255,255,255,0.1)
	})
