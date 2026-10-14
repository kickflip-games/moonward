extends Node2D

@onready var rooms: Array[Node] = $Rooms.get_children()
var room_label: Label

func _ready() -> void:
	$WinZone.endgame_cam = $CameraManager/EndgameCamera
	var canvas := CanvasLayer.new()
	canvas.layer = 2
	add_child(canvas)
	room_label = Label.new()
	room_label.position = Vector2(16, 64)
	room_label.add_theme_font_size_override("font_size", 16)
	room_label.modulate = Color("a6b9cf")
	canvas.add_child(room_label)

func _process(_delta: float) -> void:
	var player := CheckpointManager.player
	if not is_instance_valid(player):
		return
	for i in rooms.size():
		var room := rooms[i]
		if player.global_position.y > room.global_position.y - room.rise and player.global_position.y <= room.global_position.y + 80:
			room_label.text = "%02d / 30   %s" % [i + 1, room.room_name]
			return
