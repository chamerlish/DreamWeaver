@tool
extends Sprite3D

class_name PositionIndicator

@export var color: Color = Color.WHITE:
	set(value):
		color = value
		modulate = value

var time := 0.0
var speed := randf_range(1.0, 3.0)
var amplitude := 0.1
var base_scale := Vector3.ONE

func _process(delta):
	time += delta * speed
	
	var s = 1.0 + sin(time) * amplitude
	scale = base_scale * s
