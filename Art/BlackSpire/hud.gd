extends CanvasLayer
var notification:Label
var checkpoint_index:int=-1
var notification_time:float=0.0
func _ready()->void:
	var frame:=Control.new();frame.name="Presentation";add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var credit:=Label.new();credit.name="ArtCredits"
	credit.text="Terrain: BlackSpire Studio · CC BY-SA 4.0"
	credit.tooltip_text="Medieval pixel art asset FREE\nhttps://blackspirestudio.itch.io/medieval-pixel-art-asset-free\nhttps://creativecommons.org/licenses/by-sa/4.0/\nCropped and assembled for Moonward."
	credit.add_theme_font_size_override("font_size",12)
	credit.modulate=Color(.48,.5,.65,.8)
	frame.add_child(credit)
	credit.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	credit.offset_left=12;credit.offset_top=-40;credit.offset_right=410;credit.offset_bottom=-22
	credit.mouse_filter=Control.MOUSE_FILTER_PASS
	var character_credit:=Label.new();character_credit.name="CharacterCredits";frame.add_child(character_credit)
	character_credit.text="Character: Josee / N3Cloud"
	character_credit.tooltip_text="2D Pixel Art Character Template — Platformer & Metroidvania\nhttps://n3cloud.itch.io/2d-pixel-art-character-template-platformer-metroidvania\nAuthor permits personal and commercial game use; credit optional.\nOriginal pixels preserved; frames selected for Moonward."
	character_credit.add_theme_font_size_override("font_size",12);character_credit.modulate=credit.modulate
	character_credit.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	character_credit.offset_left=12;character_credit.offset_top=-24;character_credit.offset_right=410;character_credit.offset_bottom=-6
	notification=Label.new();notification.name="CheckpointNotice";frame.add_child(notification)
	notification.position=Vector2(16,36)
	notification.add_theme_font_size_override("font_size",14)
	notification.modulate=Color("a6b9cf");notification.text="Checkpoint saved";notification.hide()
	checkpoint_index=CheckpointManager.current_checkpoint_index
func _process(delta:float)->void:
	if checkpoint_index!=CheckpointManager.current_checkpoint_index:
		checkpoint_index=CheckpointManager.current_checkpoint_index
		if checkpoint_index>=0:notification_time=1.8;notification.show()
	notification_time=maxf(0,notification_time-delta)
	notification.modulate.a=minf(1,notification_time*2)
	if notification_time<=0:notification.hide()
