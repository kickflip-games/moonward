extends Node2D
const FRAMES=preload("res://Art/Characters/N3Cloud/character_frames.tres")
var character:AnimatedSprite2D
var small:AnimatedSprite2D
var picker:OptionButton
var info:Label
var paused:bool=false
var playback:float=1
var names:PackedStringArray
func _ready()->void:
	names=FRAMES.get_animation_names();names.sort()
	for index in 2:
		var actor:=AnimatedSprite2D.new();actor.sprite_frames=FRAMES;actor.centered=false
		actor.offset=Vector2(-64,-64);actor.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		actor.position=Vector2(580,420) if index==0 else Vector2(960,420)
		actor.scale=Vector2.ONE*(4 if index==0 else .75);add_child(actor)
		if index==0:character=actor
		else:small=actor
	var canvas:=CanvasLayer.new();add_child(canvas)
	var column:=VBoxContainer.new();column.position=Vector2(20,20);column.size=Vector2(420,300);canvas.add_child(column)
	var title:=Label.new();title.text="N3Cloud character animation preview";column.add_child(title)
	picker=OptionButton.new();column.add_child(picker)
	for name in names:picker.add_item(name)
	picker.item_selected.connect(_select)
	var row:=HBoxContainer.new();column.add_child(row)
	for item in [["Pause / Space",_toggle_pause],["Previous frame",_previous],["Next frame",_next]]:
		var button:=Button.new();button.text=item[0];button.pressed.connect(item[1]);row.add_child(button)
	var speed:=HSlider.new();speed.min_value=.25;speed.max_value=2;speed.step=.25;speed.value=1;column.add_child(speed)
	speed.value_changed.connect(func(value:float):playback=value;_apply_speed())
	info=Label.new();column.add_child(info)
	var keys:=Label.new();keys.text="[ / ] animation · Space pause · Left/Right step\nF flip facing · slider changes speed\nLarge: 4× source pixels. Small: actual game scale .75.\nAll frames share the same (64,64) source anchor.";column.add_child(keys)
	_select(names.find("idle"));queue_redraw()
func _select(index:int)->void:
	picker.select(index)
	for actor in [character,small]:actor.play(names[index]);actor.frame=0
	_apply_speed()
func _apply_speed()->void:
	for actor in [character,small]:actor.speed_scale=0 if paused else playback
func _toggle_pause()->void:paused=not paused;_apply_speed()
func _step(amount:int)->void:
	paused=true;_apply_speed()
	var count:=FRAMES.get_frame_count(character.animation)
	var next:=posmod(character.frame+amount,count)
	for actor in [character,small]:actor.set_frame_and_progress(next,0)
func _next()->void:_step(1)
func _previous()->void:_step(-1)
func _process(_delta:float)->void:
	info.text="%s · frame %d / %d · %.2f× speed · %s"%[character.animation,character.frame,FRAMES.get_frame_count(character.animation)-1,playback,"paused" if paused else "playing"]
func _input(event:InputEvent)->void:
	if not event is InputEventKey or not event.pressed:return
	if event.keycode not in [KEY_SPACE,KEY_LEFT,KEY_RIGHT,KEY_BRACKETLEFT,KEY_BRACKETRIGHT,KEY_F]:return
	get_viewport().set_input_as_handled()
	match event.keycode:
		KEY_SPACE:_toggle_pause()
		KEY_LEFT:_previous()
		KEY_RIGHT:_next()
		KEY_BRACKETLEFT:_select(posmod(picker.selected-1,names.size()))
		KEY_BRACKETRIGHT:_select(posmod(picker.selected+1,names.size()))
		KEY_F:
			for actor in [character,small]:actor.flip_h=not actor.flip_h
func _draw()->void:
	draw_rect(Rect2(0,0,4000,2400),Color("101022"))
	draw_line(Vector2(430,420),Vector2(1040,420),Color("b65656"),2)
	draw_rect(Rect2(947,396,26,24),Color(.5,.6,.8,.5),false)
