extends Node2D

## Switching between fullscreen and not fullscreen by pressing esc

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		swap_fullscreen_mode()

func swap_fullscreen_mode():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		
# ---- Settings ----
@export var bus_name: String = "Master"   # Bus that has SpectrumAnalyzer
@export var bass_from_hz: float = 35.0    # Kick drum lower bound
@export var bass_to_hz: float = 50.0     # Kick drum upper bound
@export var threshold: float = 0.1       # Sensitivity
@export var cooldown_ms: int = 180        # Minimum gap between triggers (ms)

@onready var bg: ColorRect = $Map/Background
@onready var bgcolor: ColorRect = $Map/Background
@export var normal_bg_color: Color =  Color("#4bacc3")

@onready var particles := $CPUParticles2D
var base_scale = 1.0
var kick_scale = 3.0
var tween: Tween


# ---- Internal ----
var spectrum: AudioEffectSpectrumAnalyzerInstance = null
var last_trigger_time: int = 0
var prev_bass: float = 0.0

func _ready() -> void:
	# Save the "default" background color so we can return to it
	normal_bg_color = bg.color
	
	$Map/Platforms.z_index = 0
	$CPUParticles2D.z_index = -1

	particles.position = get_viewport_rect().size / 2
	particles.emitting = true
	particles.restart()
	
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		push_error("Audio bus not found: %s" % bus_name)
		return

	var effect_count: int = AudioServer.get_bus_effect_count(bus_idx)
	for i: int in range(effect_count):
		var inst: AudioEffectInstance = AudioServer.get_bus_effect_instance(bus_idx, i)
		if inst is AudioEffectSpectrumAnalyzerInstance:
			spectrum = inst as AudioEffectSpectrumAnalyzerInstance
			break

	if spectrum == null:
		push_error("No SpectrumAnalyzer effect found on bus '%s'." % bus_name)
		return
		




func _process(delta: float) -> void:
	if spectrum == null:
		return

	# Get bass magnitude (Vector2: left/right → combine with length)
	var v: Vector2 = spectrum.get_magnitude_for_frequency_range(bass_from_hz, bass_to_hz)
	var bass: float = v.length()

	# Smooth the signal a bit
	var smooth: float = lerp(prev_bass, bass, 0.25)
	prev_bass = smooth

	# Detect trigger
	var now: int = Time.get_ticks_msec()
	if smooth > threshold and (now - last_trigger_time) > cooldown_ms:
		_on_kick(smooth)
		last_trigger_time = now
		
	$CPUParticles2D.position = $Camera2D.global_position

func _on_kick(strength: float) -> void:
	# Pulse the bg visually when kick is detected
	# Pick a flash color (random or fixed)
	#var deviation: float = 0.4

	#var r: float = clamp(normal_bg_color.r + randf_range(-deviation, deviation), 0.0, 1.0)
	#var g: float = clamp(normal_bg_color.g + randf_range(-deviation, deviation), 0.0, 1.0)
	#var b: float = clamp(normal_bg_color.b + randf_range(-deviation, deviation), 0.0, 1.0)
	
	var flash_color_val_r: float = normal_bg_color.r + 0.02
	var flash_color_val_g: float = normal_bg_color.r + 0.02
	var flash_color_val_b: float = normal_bg_color.r + 0.02

	var flash_color: Color = Color(flash_color_val_r, flash_color_val_g, flash_color_val_b)
	
	# Instantly set to flash color
	bg.color = flash_color
	
	if tween:
		tween.kill()  # cancel any old tweens
		
	tween = create_tween()
	# Jump up to kick speed fast
	tween.tween_property(particles, "speed_scale", kick_scale, 0.05)
	tween.tween_property(particles, "speed_scale", base_scale, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	


	# Tween back to normal color over 0.15 seconds
	var t: Tween = create_tween()
	t.tween_property(bg, "color", normal_bg_color, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
