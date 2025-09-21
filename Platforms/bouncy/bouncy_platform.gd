extends StaticBody2D

@export var bounce_force: float = 2500.0
@export var bounce_direction: Vector2 = Vector2(0, -1)
@export var use_node_up_as_direction: bool = true
@export var bounce_cooldown: float = 0.15
@export var preserve_horizontal_velocity: bool = true
@export var velocity_boost_multiplier: float = 1.0

# Animation settings
@export_group("Animation")
@export var squash_amount: float = 0.4
@export var stretch_amount: float = 1.3
@export var anticipation_time: float = 0.04
@export var squash_time: float = 0.08
@export var stretch_time: float = 0.15
@export var settle_time: float = 0.2

signal bounced

@onready var platform_sprite: Sprite2D = $Sprite2D
@onready var stem_sprite: Sprite2D = $Stem
@onready var area: Area2D = $Area2D

var can_bounce: bool = true
var original_platform_pos: Vector2
var original_stem_pos: Vector2
var original_platform_scale: Vector2  # Store original scale
var original_stem_scale: Vector2       # Store original scale

func _ready():
	area.body_entered.connect(_on_body_entered)
	# Store original positions AND scales
	original_platform_pos = platform_sprite.position
	original_stem_pos = stem_sprite.position
	original_platform_scale = platform_sprite.scale  # Capture actual starting scale
	original_stem_scale = stem_sprite.scale           # Capture actual starting scale

func _on_body_entered(body):
	if body.is_in_group("Player") and can_bounce:
		bounce_player(body)

func bounce_player(player):
	can_bounce = false
	
	# Determine bounce direction
	var dir = bounce_direction
	if use_node_up_as_direction:
		dir = -transform.y
	
	# Calculate bounce velocity
	var bounce_velocity = dir.normalized() * bounce_force
	
	# Preserve existing velocity and add bounce
	if preserve_horizontal_velocity:
		var new_velocity = Vector2()
		new_velocity.x = player.velocity.x * velocity_boost_multiplier
		new_velocity.y = bounce_velocity.y
		
		if abs(bounce_direction.x) > 0:
			new_velocity.x += bounce_velocity.x
		
		player.velocity = new_velocity
	else:
		player.velocity += bounce_velocity
	
	animate_enhanced_bounce()
	emit_signal("bounced")
	
	# Reset cooldown
	await get_tree().create_timer(bounce_cooldown).timeout
	can_bounce = true

func animate_enhanced_bounce():
	var tween = create_tween().set_parallel(true)
	
	# PHASE 1: Tiny anticipation (scale relative to original)
	var anticipation_scale = Vector2(
		original_platform_scale.x * 1.05, 
		original_platform_scale.y * 1.02
	)
	tween.tween_property(platform_sprite, "position:y", original_platform_pos.y - 2, anticipation_time)
	tween.tween_property(platform_sprite, "scale", anticipation_scale, anticipation_time)
	
	# PHASE 2: Big squash (scale relative to original)
	var squash_scale = Vector2(
		original_platform_scale.x * 1.4, 
		original_platform_scale.y * squash_amount
	)
	tween.tween_property(platform_sprite, "scale", squash_scale, squash_time) \
		.set_delay(anticipation_time) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_BACK)
	
	tween.tween_property(platform_sprite, "position:y", original_platform_pos.y + 8, squash_time) \
		.set_delay(anticipation_time) \
		.set_ease(Tween.EASE_OUT)
	
	# PHASE 3: Spring stretch (scale relative to original)
	var stretch_scale = Vector2(
		original_platform_scale.x * 0.8, 
		original_platform_scale.y * stretch_amount
	)
	var stretch_delay = anticipation_time + squash_time
	tween.tween_property(platform_sprite, "scale", stretch_scale, stretch_time) \
		.set_delay(stretch_delay) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_ELASTIC)
	
	tween.tween_property(platform_sprite, "position:y", original_platform_pos.y - 5, stretch_time) \
		.set_delay(stretch_delay) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_ELASTIC)
	
	# PHASE 4: Settle back to ORIGINAL scale (not Vector2.ONE)
	var settle_delay = anticipation_time + squash_time + stretch_time
	tween.tween_property(platform_sprite, "scale", original_platform_scale, settle_time) \
		.set_delay(settle_delay) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_ELASTIC)
	
	tween.tween_property(platform_sprite, "position", original_platform_pos, settle_time) \
		.set_delay(settle_delay) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_ELASTIC)
	
	animate_stem(tween)

func animate_stem(tween: Tween):
	# Stem compresses (scale relative to original)
	var stem_squash_scale = Vector2(
		original_stem_scale.x * 1.1, 
		original_stem_scale.y * 0.7
	)
	tween.tween_property(stem_sprite, "scale", stem_squash_scale, squash_time) \
		.set_delay(anticipation_time + 0.02) \
		.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(stem_sprite, "position:y", original_stem_pos.y + 3, squash_time) \
		.set_delay(anticipation_time + 0.02)
	
	# Stem stretches (scale relative to original)
	var stem_stretch_scale = Vector2(
		original_stem_scale.x * 0.95, 
		original_stem_scale.y * 1.1
	)
	var stretch_delay = anticipation_time + squash_time + 0.03
	tween.tween_property(stem_sprite, "scale", stem_stretch_scale, stretch_time * 0.8) \
		.set_delay(stretch_delay) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_ELASTIC)
	
	# Stem settles back to ORIGINAL scale
	var settle_delay = anticipation_time + squash_time + stretch_time + 0.05
	tween.tween_property(stem_sprite, "scale", original_stem_scale, settle_time) \
		.set_delay(settle_delay) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_ELASTIC)
	
	tween.tween_property(stem_sprite, "position", original_stem_pos, settle_time) \
		.set_delay(settle_delay) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_ELASTIC)
