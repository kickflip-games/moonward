@tool
extends "res://World/Map/dungeon_skin.gd"

## Add a new chapter before the original scaffold shaft. Nothing is removed.
## The upper original tower translates as a unit, including hazards and summit.
const INSERT_AT := -4192
const ADDED_HEIGHT := 2304
const FRAGILE = preload("res://Platforms/breakable/BreakablePlatform.tscn")
const LIFT = preload("res://Platforms/MovingPlatform.tscn")
const SHRINE = preload("res://Checkpoint/Checkpoint.tscn")
const TRAP = preload("res://World/Tower/trap.gd")
const MOUNT = preload("res://World/Tower/trap_mount.gd")
var built := false

func _ready() -> void:
	if not built:
		build_ascent()
		built = true
	super._ready()

func stone(x: int, y: int, w: int, h: int) -> void:
	assert(x % 32 == 0 and y % 32 == 0 and w % 32 == 0 and h % 32 == 0)
	for cx in range(x / 32, (x + w) / 32):
		for cy in range(y / 32, (y + h) / 32):
			$GameLayer.set_cell(Vector2i(cx, cy), 0, Vector2i(1, 1))

func shelf(x: int, y: int, w: int) -> void:
	stone(x, y, w, 32)
	# Chipped shoulders and a tapered underside use the original collision tiles.
	$GameLayer.set_cell(Vector2i(x / 32, y / 32 + 1), 0, Vector2i(0, 2))
	$GameLayer.set_cell(Vector2i((x + w) / 32 - 1, y / 32 + 1), 0, Vector2i(2, 2))
	if w > 64:stone(x + 32, y + 32, w - 64, 32)

func fragile(label: String, at: Vector2) -> void:
	var platform := FRAGILE.instantiate()
	platform.name = label
	platform.position = at - $Platforms.position
	platform.scale.x = 0.62 # 95px footing; preserve vertical hitbox and jump clearance.
	platform.break_delay = 0.48
	platform.fade_duration = 0.18
	platform.respawn_delay = 2.4
	$Platforms.add_child(platform)

func lift(label: String, at: Vector2, travel: Vector2, speed_value: float) -> void:
	var platform := LIFT.instantiate()
	platform.name = label
	platform.position = at - $Platforms.position
	platform.move_to = travel
	platform.speed = speed_value
	platform.delay = 0.35
	platform.get_node("ActualPlatform").scale.x = 0.7
	$Platforms.add_child(platform)

func shrine(label: String, at: Vector2) -> void:
	var checkpoint := SHRINE.instantiate()
	checkpoint.name = label
	checkpoint.position = at
	$Checkpoints.add_child(checkpoint)

func hazard(label: String, at: Vector2, travel: Vector2, kind: String, cycle: float) -> void:
	var trap := Area2D.new()
	trap.set_script(TRAP)
	trap.name = label
	trap.position = at
	trap.kind = kind
	trap.size = Vector2(40, 40)
	trap.travel = travel
	trap.period = cycle
	trap.collision_layer = 4
	trap.collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18
	shape.shape = circle
	trap.add_child(shape)
	$ReferenceMechanisms.add_child(trap)
	var mount := Node2D.new()
	mount.set_script(MOUNT)
	mount.name = label + "Mount"
	mount.position = at
	mount.trap_path = NodePath("../" + label)
	mount.z_index = -1
	$ReferenceMechanisms.add_child(mount)

func extend_original_tower() -> void:
	for layer in [$GameLayer, $Detailing]:
		var moved: Array = []
		for cell in layer.get_used_cells():
			if cell.y * 32 < INSERT_AT:
				moved.append([cell, layer.get_cell_source_id(cell), layer.get_cell_atlas_coords(cell), layer.get_cell_alternative_tile(cell)])
		for tile in moved:layer.erase_cell(tile[0])
		for tile in moved:layer.set_cell(tile[0] - Vector2i(0, ADDED_HEIGHT / 32), tile[1], tile[2], tile[3])
	# Move roots only: child collision shapes, tween endpoints and turret parts
	# retain their local coordinates and their original behaviour.
	for container in [$Platforms, $Checkpoints, $Spikes, $Turrets]:
		for node in container.get_children():
			if node.position.y + container.position.y < INSERT_AT:
				node.position.y -= ADDED_HEIGHT
	for node in [$WinZone, $Moon, $CameraManager/EndgameCamera, $Ui/EndGame]:
		node.position.y -= ADDED_HEIGHT
	var frame := get_parent().get_node_or_null("HazardRoomFrame")
	if frame:frame.position.y -= ADDED_HEIGHT
	# Continue the outer walls across the inserted chapter.
	stone(-2048, INSERT_AT - ADDED_HEIGHT, 256, ADDED_HEIGHT)
	stone(-32, INSERT_AT - ADDED_HEIGHT, 192, ADDED_HEIGHT)

func build_ascent() -> void:
	extend_original_tower()
	var mechanisms := Node2D.new()
	mechanisms.name = "ReferenceMechanisms"
	add_child(mechanisms)

	# Collapsing Stair / Broken Bridge: commit to four alternating 144px climbs.
	fragile("Stair01", Vector2(-1216, -4278))
	fragile("Stair02", Vector2(-1440, -4422))
	fragile("Stair03", Vector2(-1216, -4566))
	fragile("Stair04", Vector2(-1472, -4710))
	stone(-1792, -4800, 288, 64)
	stone(-1792, -4736, 160, 288)
	shrine("StairRest", Vector2(-1600, -4808))

	# Counterweight Lift / Relay Lifts: actual 224px vertical and 320px horizontal
	# travel. The stone transfer perch is the sole permanent footing in the middle.
	lift("Counterweight", Vector2(-1408, -4976), Vector2(0, 112), 90)
	shelf(-1216, -5184, 128)
	lift("Relay", Vector2(-896, -5328), Vector2(-160, 0), 110)
	stone(-704, -5504, 672, 64)
	stone(-512, -5440, 480, 160)
	shrine("RelayRest", Vector2(-608, -5512))

	# Needle Threader / Pendulum Court: alternating teeth and wall buttresses,
	# with blades sweeping the gaps and a fragile link into the upper shaft.
	shelf(-928, -5664, 96)
	stone(-1792, -5792, 672, 96)
	stone(-1792, -5696, 480, 64)
	stone(-928, -5952, 896, 96)
	stone(-736, -5856, 704, 64)
	stone(-1792, -6080, 672, 64)
	stone(-1792, -6016, 480, 32)
	fragile("CrownLink", Vector2(-1104, -6230))
	$Platforms/CrownLink.break_delay = 0.85
	stone(-1056, -6400, 64, 192)
	shelf(-1408, -6400, 160)
	shrine("ScaffoldRest", Vector2(-1328, -6408))
	hazard("NeedleSaw", Vector2(-1024, -5712), Vector2(72, 0), "saw", 3.4)
	hazard("CourtPendulum", Vector2(-1024, -6000), Vector2(88, 64), "pendulum", 4.2)

	# Keep retry shrines at chapter boundaries, ordered with the original ten.
	var ordered := $Checkpoints.get_children()
	ordered.sort_custom(func(a, b): return a.position.y > b.position.y)
	for i in ordered.size():ordered[i].progression_index = i

func apply_visuals() -> void:
	super.apply_visuals()
	if has_node("TowerDepth"):
		$TowerDepth.height_span = 6000.0 + ADDED_HEIGHT
	if not has_node("BlackSpireDecorations"):return
	# Wall anchors and hanging ironwork give the additions the tower's material
	# language. Background props never alter the traversable silhouettes.
	for at in [Vector2(-1680, -4580), Vector2(-384, -5380)]:
		prop("window", at, 2, false).modulate = Color(.4, .43, .63)
	for at in [Vector2(-1600, -4870), Vector2(-608, -5580)]:
		prop("torch", at + Vector2(100, 20), 2)
