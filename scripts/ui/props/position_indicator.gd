@tool
extends Sprite3D

class_name PositionIndicator

@export var color: Color = Color.WHITE:
	set(value):
		color = value
		modulate = value
