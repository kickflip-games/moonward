extends Node2D
var body:Node2D
var anchor:=Vector2.ZERO
func _process(_delta:float)->void:queue_redraw()
func _draw()->void:
	if not is_instance_valid(body):return
	var endpoint:=to_local(body.global_position)+Vector2(0,-16)
	draw_line(anchor,endpoint,Color("544268"),3)
	draw_circle(anchor,5,Color("b65656"))
