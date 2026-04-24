extends Area3D
class_name CameraSwitchZone

@onready var camera_node: Camera3D = $Camera3D

signal switch_camera(new_camera: Camera3D)

@export var is_trail: bool = false
@export var trail_follower: PathFollow3D
@export var trail_path: Path3D

var player: Player

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if "Player" in body.get_groups():
		switch_camera.emit(camera_node)
