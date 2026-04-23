class_name Player
extends CharacterBody3D


@export var can_move : bool = true
@export var has_gravity : bool = true
@export var can_sprint : bool = false
@export var can_freefly : bool = false

@export_group("Horizontal Movement")
@export var max_speed: float = 0.01
@export_range(1.0, 5.0) var max_ground_velocity_ratio: float

@export_subgroup("On Floor")
@export_range(0.0, 1.0) var running_acc_time: float
@export_range(0.0, 1.0) var running_dec_time: float

@export_subgroup("In Air")
@export_range(0.0, 1.0) var jumping_acc_time: float
@export_range(0.0, 1.0) var jumping_dec_time: float
@export_range(0.0, 1.0) var falling_acc_time: float
@export_range(0.0, 1.0) var falling_dec_time: float

@export_group("Vertical Movement")
@export_subgroup("Gravity")
@export_range(1.0, 2.0) var jump_not_held_gravity_ratio: float
@export_range(1.0, 2.0) var down_held_gravity_ratio: float
@export var gravity_limit: float
@export_range(1.0, 2.0) var down_held_gravity_limit_ratio: float

@export_subgroup("Jump")
@export var jump_height: float
@export_range(0.0, 1.0) var jump_time_to_peak: float
@export_range(0.0, 1.0) var jump_time_to_land: float
@export_range(1.0, 5.0) var max_up_velocity_ratio: float
@export var jump_peak_boost: float
@export_range(0.0, 1.0) var jump_peak_gravity_ratio: float
@export var corner_correction_distance: int
@export var oneway_platform_assist_distance: int

@export_group("On Wall")
@export_subgroup("Wall Slide")
@export var max_wall_slide_speed: float
@export_range(1.0, 2.0) var down_held_wall_slide_ratio: float
@export_range(0.0, 1.0) var wall_slide_acc_time: float

@export_subgroup("Wall Jump")
@export_range(0.0, 1.0) var wall_jump_v_velocity_ratio: float
@export var wall_jump_h_velocity: float
@export_range(0.0, 1.0) var wall_jumping_acc_time: float
@export_range(0.0, 1.0) var wall_jumping_dec_time: float
@export_range(0.0, 1.0) var wall_jumping_towards_wall_dec_time: float

@export_group("Dash")
@export var dash_speed: float
@export var dash_power: float = 10
@export_range(0.0, 1.0) var after_dash_gravity_ratio: float

var dash_allowed: bool = true

@export_group("Speeds")
@export var look_speed : float = 0.002
@export var base_speed : float = 200.0
@export var jump_velocity : float = 4.5
@export var sprint_speed : float = 10.0
@export var freefly_speed : float = 25.0

@export_group("Input Actions")
@export var input_left : String = "move_left"
@export var input_right : String = "move_right"
@export var input_forward : String = "move_up"
@export var input_back : String = "move_down"
@export var input_jump : String = "jump"
@export var input_sprint : String = "sprint"
@export var input_freefly : String = "freefly"


@onready var jump_peak_gravity_timer: Timer = %JumpPeakGravity as Timer
@onready var jump_coyote_timer: Timer = %JumpCoyote as Timer
@onready var jump_buffer_timer: Timer = %JumpBuffer as Timer
@onready var wall_jump_coyote_timer: Timer = %WallJumpCoyote as Timer
@onready var wall_jump_buffer_timer: Timer = %WallJumpBuffer as Timer
@onready var dash_cooldown_timer: Timer = %DashCooldown as Timer
@onready var after_dash_gravity_timer: Timer = %AfterDashGravity as Timer

@onready var max_ground_velocity: float = max_speed * max_ground_velocity_ratio


var mouse_captured : bool = false
var move_speed : float = 0.0
var freeflying : bool = false

@onready var collider: CollisionShape3D = $Collider
@onready var state_machine: StateMachine = $StateMachine as StateMachine


var position_indicator: PackedScene = preload("res://scenes/ui/props/position_indicator.tscn")
var floor_indicator: PositionIndicator = position_indicator.instantiate()


func _ready() -> void:
	check_input_mappings()
	get_parent().add_child.call_deferred(floor_indicator)
	floor_indicator.color = Color.DEEP_SKY_BLUE
	
	
	dash_point.hide()


func _unhandled_input(event: InputEvent) -> void:
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if freeflying:
			disable_freefly()
		else:
			enable_freefly()


func apply_gravity(delta: float) -> void:
	if has_gravity and not is_on_floor():
		velocity.y += get_gravity().y * delta * 2


func get_input_vector() -> Vector2:
	return Input.get_vector(input_left, input_right, input_forward, input_back)

func get_camera_yaw() -> Basis:
	var cam := get_viewport().get_camera_3d()
	var basis := cam.global_transform.basis

	# flatten to XZ plane (important for top-down / pitch cameras)
	basis.y = Vector3.UP
	basis.x = basis.x.normalized()
	basis.z = basis.z.normalized()

	return basis
	
func apply_movement(delta: float) -> void:
	var input_vec := get_input_vector() 
	
	if not can_move or input_vec == Vector2.ZERO:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	
	var z_forward = transform.basis.z

	velocity.x = z_forward.x * move_speed * delta
	velocity.z = z_forward.z * move_speed * delta


var current_cam_yaw: float

func look_at_dir() -> void:
	var input_dir := get_input_vector()
	var cam := get_viewport().get_camera_3d()

	var cam_yaw: float = cam.global_transform.basis.get_euler().y
	
	if input_dir == Vector2.ZERO:
		current_cam_yaw = cam_yaw
		return
	
	var forward := Vector3(
		sin(current_cam_yaw),
		0,
		cos(current_cam_yaw)
	)

	var right := Vector3(
		cos(current_cam_yaw),
		0,
		-sin(current_cam_yaw)
	)

	var dir := right * -input_dir.x + forward * -input_dir.y

	if dir.length() == 0:
		return

	look_at(global_position + dir.normalized(), Vector3.UP)

func show_landing_pos(floor_ind: PositionIndicator) -> void:
	if track_floor() != Vector3.INF and !is_on_floor():
		floor_ind.show()
		floor_ind.global_position = track_floor()
	else:
		floor_ind.hide()


func _physics_process(_delta: float) -> void:
	if can_sprint and Input.is_action_pressed(input_sprint):
		move_speed = sprint_speed
	else:
		move_speed = base_speed
		
	


func enable_freefly() -> void:
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO


func disable_freefly() -> void:
	collider.disabled = false
	freeflying = false


func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


func check_input_mappings() -> void:
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
		can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false


#region DASH

@onready var dash_point: Marker3D = $DashPoint
@onready var dash_indicator: PositionIndicator = dash_point.get_node("PositionIndicator")

@onready var dash_distance: float = abs(global_position.z - dash_indicator.global_position.z)
func _track_dash() -> Vector3:
	var floor_raycast: RayCast3D = dash_point.get_node("DashRaycast")
	floor_raycast.force_raycast_update()
	if floor_raycast.is_colliding():
		return floor_raycast.get_collision_point() + Vector3(0, 0.1, 0)
	return Vector3.INF

func show_dash_pos(dash_ind: PositionIndicator) -> void:
	if _track_dash() != Vector3.INF:
		dash_ind.global_position = _track_dash()

func can_dash() -> bool:
	return dash_allowed and dash_cooldown_timer.is_stopped()

func try_dash() -> void:
	if Input.is_action_just_pressed("dash") and can_dash():
		state_machine.activate_state_by_name.call_deferred("DashPrepareState")

func start_dash() -> void:
	var direction = transform.basis.z
	var horizontal_force = direction * dash_power
	
	velocity.x = horizontal_force.x
	velocity.z = horizontal_force.z
	dash_allowed = false
	

func stop_dash():
	velocity.z = 0
	velocity.x = 0
	dash_allowed = true

#endregion

#region JUMP

var can_jump: bool

func _refresh_can_jump():
	if is_on_floor():
		can_jump = true

func jump() -> void:
	velocity.y = jump_velocity
	can_jump = false


func try_jump() -> void:
	_refresh_can_jump()
	if Input.is_action_just_pressed(input_jump) and can_jump:
		try_coyote_jump()


func try_coyote_jump() -> void:
	if is_on_floor() or not jump_coyote_timer.is_stopped():
		jump()


func try_jump_buffer_timer() -> void:
	if Input.is_action_just_pressed(input_jump):
		jump_buffer_timer.start()


func try_buffer_jump() -> void:
	if not jump_buffer_timer.is_stopped():
		jump()


func stop_jump_timers() -> void:
	jump_coyote_timer.stop()
	jump_buffer_timer.stop()
	wall_jump_coyote_timer.stop()
	wall_jump_buffer_timer.stop()

#endregion

func track_floor() -> Vector3:
	var floor_raycast: RayCast3D = $FloorRaycast
	floor_raycast.force_raycast_update()
	if floor_raycast.is_colliding():
		return floor_raycast.get_collision_point() + Vector3(0, 0.1, 0)
	return Vector3.INF
