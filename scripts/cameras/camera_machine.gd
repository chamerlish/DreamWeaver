extends Node3D
class_name CameraMachine

var all_cameras: Array[CameraSwitchZone]

var current_cam_index: int

@export var player_node: Player

func scan_cameras() -> Array[CameraSwitchZone]:
	var res: Array[CameraSwitchZone]
	for child in get_children():
		if child is CameraSwitchZone:
			res.append(child)
			child.player = player_node 
			child.switch_camera.connect(switch_camera)
	
	return res

func _ready() -> void:
	all_cameras = scan_cameras()
	transition_camera(0)

func _process(delta: float) -> void:
	if current_switch_zone.is_trail:
		camera_follow_trail()

@export var main_track: PathFollow3D
@export var camera: Camera3D

var current_switch_zone: CameraSwitchZone

func switch_camera(new_camera: Camera3D):
	for cam_switch_index in range(all_cameras.size()):
		if all_cameras[cam_switch_index].camera_node == new_camera:
			transition_camera(cam_switch_index)

const TRANSITION_SPEED: float = 0.5

func transition_camera(new_index: int):
	
	current_switch_zone = all_cameras[new_index]
	
	var target_rotation: Vector3 = current_switch_zone.camera_node.rotation
	var target_position: Vector3 = current_switch_zone.camera_node.global_position
	var target_fov: float = current_switch_zone.camera_node.fov
	
	var rotate_pos_fov_tween = get_tree().create_tween().set_parallel()
	
	rotate_pos_fov_tween.tween_property(camera, "rotation", target_rotation, TRANSITION_SPEED)
	rotate_pos_fov_tween.tween_property(camera, "global_position", target_position, TRANSITION_SPEED)
	rotate_pos_fov_tween.tween_property(camera, "fov", target_fov, TRANSITION_SPEED)

	if current_switch_zone.is_trail == true:
		camera.reparent(current_switch_zone.trail_follower)
		

func camera_follow_trail() -> void:
	var curve: Curve3D = current_switch_zone.trail_path.curve
	var closest_offset: float = curve.get_closest_offset(player_node.global_position)
	current_switch_zone.trail_follower.progress_ratio = closest_offset / curve.get_baked_length()
