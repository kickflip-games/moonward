extends Node2D
func _ready()->void:
	CheckpointManager.set_player($Player);HeightTracker.set_player($Player)
func _process(_delta:float)->void:
	if $Player.position.y>1800:$Player.respawn()
