class_name DashPrepareState
extends PlayerState

var start_pos: Vector3
var end_pos: Vector3
var dash_dir: float

func _enter(previous_state: State) -> void:
	start_pos = player.global_position
	end_pos = player.dash_point.global_position
	
	
	player.velocity = Vector3(player.dash_speed * dash_dir, 0.0, 0.0)
	player.dash_cooldown_timer.start()
	player.after_dash_gravity_timer.start()

func _exit(_next_state: State) -> void:
	pass

func _physics_update(_delta: float) -> void:
	player.look_at_dir()
	player.try_dash()
	player.move_and_slide()
	
	if Input.is_action_just_released("dash"):
		switch_to("DashState")
