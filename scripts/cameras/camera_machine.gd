extends Node3D
class_name CameraMachine
@export var player_node: Player
@export var trail_follower: PathFollow3D
@export var trail_path: Path3D
@export var camera: Camera3D
var path_curve: Curve3D
var path_length: float = 0.0
var fov_curve: Curve2D = Curve2D.new()
var rotation_curve: Curve3D = Curve3D.new()
var ratio: float = 0.0
var closest_offset: float = 0.0
func _ready() -> void:
	path_curve = trail_path.curve
	path_length = path_curve.get_baked_length()
	fov_curve = _create_fov_curve()
	rotation_curve = _create_rotation_curve()
func _process(delta: float) -> void:
	_update_camera(delta)
func _update_camera(_delta: float) -> void:
	if path_length <= 0.0:
		return
	closest_offset = path_curve.get_closest_offset(player_node.global_position)
	ratio = closest_offset / path_length
	trail_follower.progress_ratio = ratio
	camera.global_position = trail_follower.global_position
	_apply_rotation_curve()
	camera.fov = _sample_fov(ratio)
func _apply_rotation_curve() -> void:
	var rot_curve_length: float = rotation_curve.get_baked_length()
	var target_position: Vector3 = rotation_curve.sample_baked(ratio * rot_curve_length)
	var target_basis: Basis = Basis.looking_at(target_position - camera.global_position)
	camera.global_transform.basis = target_basis
func _sample_fov(t: float) -> float:
	var length: float = fov_curve.get_baked_length()
	return fov_curve.sample_baked(t * length).y
func _create_fov_curve() -> Curve2D:
	var res: Curve2D = Curve2D.new()
	var cameras: Array[CameraSwitchZone] = _get_sorted_cameras()
	for i: int in range(cameras.size()):
		var cam: CameraSwitchZone = cameras[i]
		var offset: float = path_curve.get_closest_offset(cam.camera_node.global_position)
		var normalized: float = offset / path_length
		var fov: float = cam.camera_node.fov
		var in_tangent: Vector2 = Vector2.ZERO
		var out_tangent: Vector2 = Vector2.ZERO
		if i > 0:
			var prev_fov: float = cameras[i - 1].camera_node.fov
			in_tangent = Vector2(0.0, (fov - prev_fov) * 0.5)
		if i < cameras.size() - 1:
			var next_fov: float = cameras[i + 1].camera_node.fov
			out_tangent = Vector2(0.0, (next_fov - fov) * 0.5)
		res.add_point(Vector2(normalized, fov), in_tangent, out_tangent)
	return res
func _create_rotation_curve() -> Curve3D:
	var res: Curve3D = Curve3D.new()
	var cameras: Array[CameraSwitchZone] = _get_sorted_cameras()
	for i: int in range(cameras.size()):
		var cam: CameraSwitchZone = cameras[i]
		var target_pos: Vector3 = cam.camera_node.global_position + cam.camera_node.global_transform.basis.z * -1000.0
		var in_tangent: Vector3 = Vector3.ZERO
		var out_tangent: Vector3 = Vector3.ZERO
		if i > 0:
			var prev_target: Vector3 = cameras[i - 1].camera_node.global_position + cameras[i - 1].camera_node.global_transform.basis.z * -1000.0
			in_tangent = (target_pos - prev_target) * 0.5
		if i < cameras.size() - 1:
			var next_target: Vector3 = cameras[i + 1].camera_node.global_position + cameras[i + 1].camera_node.global_transform.basis.z * -1000.0
			out_tangent = (next_target - target_pos) * 0.5
		res.add_point(target_pos, in_tangent, out_tangent)
	return res
func _get_sorted_cameras() -> Array[CameraSwitchZone]:
	var cams: Array[CameraSwitchZone] = []
	for child: Node in get_children():
		if child is CameraSwitchZone:
			cams.append(child)
	cams.sort_custom(func(a: CameraSwitchZone, b: CameraSwitchZone) -> bool:
		var a_offset: float = path_curve.get_closest_offset(a.camera_node.global_position)
		var b_offset: float = path_curve.get_closest_offset(b.camera_node.global_position)
		return a_offset < b_offset
	)
	return cams
