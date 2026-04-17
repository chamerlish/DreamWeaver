class_name Player
extends CharacterBody3D


@export var can_move : bool = true
@export var has_gravity : bool = true
@export var can_jump : bool = true
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
@export var dash_distance: float
@export var after_dash_speed: float
@export_range(0.0, 1.0) var after_dash_gravity_ratio: float

var dash_allowed: bool = false

@export_group("Speeds")
@export var look_speed : float = 0.002
@export var base_speed : float = 7.0
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
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false

@onready var collider: CollisionShape3D = $Collider


func _ready() -> void:
	check_input_mappings()
	look_rotation.y = rotation.y


func _unhandled_input(event: InputEvent) -> void:
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if freeflying:
			disable_freefly()
		else:
			enable_freefly()


func apply_gravity(delta: float) -> void:
	if has_gravity and not is_on_floor():
		velocity.y += get_gravity().y * delta


func get_input_vector() -> Vector2:
	return Input.get_vector(input_left, input_right, input_forward, input_back)


func apply_movement(delta: float, acc_time: float, dec_time: float) -> void:
	var input_vec := get_input_vector()
	
	if not can_move or input_vec == Vector2.ZERO:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var move_dir := (transform.basis * Vector3(input_vec.x, 0, input_vec.y)).normalized()
	var target_velocity := move_dir * move_speed

	var current := Vector2(velocity.x, velocity.z)
	var target := Vector2(target_velocity.x, target_velocity.z)

	var apply_acc := current == Vector2.ZERO or current.dot(target - current) <= 0.0
	var time := maxf(acc_time if apply_acc else dec_time, 0.001)
	var step := max_speed / time

	current = current.move_toward(target, step * delta)
	
	var z_forward = transform.basis.z

	velocity.x = z_forward.x
	velocity.z = z_forward.z


func look_at_dir() -> void:
	var input_dir := get_input_vector()
	if input_dir != Vector2.ZERO:
		rotation.y = atan2(input_dir.x, input_dir.y)


func _physics_process(delta: float) -> void:
	if freeflying and can_freefly:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		if input_dir != Vector2.ZERO:
			var motion := Vector3(input_dir.x, 0, input_dir.y).normalized() * freefly_speed * delta
			move_and_collide(motion)
		return

	look_at_dir()
	apply_gravity(delta)

	if can_sprint and Input.is_action_pressed(input_sprint):
		move_speed = sprint_speed
	else:
		move_speed = base_speed

	move_and_slide()


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


func jump() -> void:
	velocity.y = jump_velocity


func try_jump() -> void:
	if Input.is_action_just_pressed(input_jump):
		jump()


func try_coyote_jump() -> void:
	if not jump_coyote_timer.is_stopped():
		try_jump()


func try_jump_buffer_timer() -> void:
	if Input.is_action_just_pressed(input_jump):
		jump_buffer_timer.start()


func try_buffer_jump() -> void:
	if not jump_buffer_timer.is_stopped():
		jump()


func try_dash() -> void:
	pass


func stop_jump_timers() -> void:
	jump_coyote_timer.stop()
	jump_buffer_timer.stop()
	wall_jump_coyote_timer.stop()
	wall_jump_buffer_timer.stop()
