extends StaticBody2D

@export var break_delay: float = 1.0  # Time before breaking after stepped on
@export var respawn_delay: float = 3.0  # Time before respawning
@export var shake_intensity: float = 2.0  # Visual shake before breaking
@export var fade_duration: float = 0.5  # How long the fade out/in takes

@onready var collision_shape = $CollisionShape2D
@onready var sprite = $Sprite2D
@onready var timer = $Timer
@onready var detection_area = $DetectionArea

var original_position: Vector2
var is_breaking = false
var is_broken = false
var shake_timer = 0.0

func _ready():
	original_position = sprite.position
	detection_area.body_entered.connect(_on_body_entered)

func _process(delta):
	if is_breaking and not is_broken:
		# Shake effect
		shake_timer += delta * 10
		sprite.position = original_position + Vector2(
			sin(shake_timer) * shake_intensity,
			cos(shake_timer * 1.5) * shake_intensity * 0.5
		)

func _on_body_entered(body):
	if body.is_in_group("Player") and not is_breaking and not is_broken:
		start_breaking()

func start_breaking():
	is_breaking = true
	timer.wait_time = break_delay
	timer.timeout.connect(_break_platform)
	timer.start()

func _break_platform():
	is_broken = true
	is_breaking = false
	collision_shape.disabled = true
	sprite.position = original_position  # Stop shaking
	
	# Fade out animation
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(sprite, "modulate:a", 0.0, fade_duration)
	
	await fade_out_tween.finished
	
	# Start respawn timer
	timer.timeout.disconnect(_break_platform)
	timer.wait_time = respawn_delay
	timer.timeout.connect(_respawn_platform)
	timer.start()

func _respawn_platform():
	is_broken = false
	collision_shape.disabled = false
	
	# Fade in animation
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(sprite, "modulate:a", 1.0, fade_duration)
	
	await fade_in_tween.finished
	
	timer.timeout.disconnect(_respawn_platform)
