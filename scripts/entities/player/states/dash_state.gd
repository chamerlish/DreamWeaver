class_name DashState
extends PlayerState

var start_pos: Vector3
var end_pos: Vector3
var dash_dir: float
var distance: float

func _enter(previous_state: State) -> void:
	
	player.start_dash()
	player.dash_allowed = false
	start_pos = player.global_position
	end_pos = player.dash_point.position
	
	var previous_prepare_state = previous_state as DashPrepareState
	distance = previous_prepare_state.start_pos.distance_squared_to(previous_prepare_state.end_pos)
	
	
	# If the player was wall sliding, dash into the opposite direction.
	if previous_state is WallSlideState:
		player.flip_h = !player.flip_h
	
	
	player.velocity = Vector3(player.dash_speed * dash_dir, 0.0, 0.0)

func _exit(_next_state: State) -> void:
	player.stop_dash()
	#player.velocity.x = player.after_dash_speed * dash_dir
	player.dash_cooldown_timer.start()
	player.after_dash_gravity_timer.start()
	
	start_pos = Vector3.ZERO

func _physics_update(_delta: float) -> void:
	
	player.move_and_slide()
	player.start_dash()
	player.show_landing_pos(player.floor_indicator)
	#if (player.global_position.distance_to(end_pos) <= 0.1
	#	or player.is_on_wall()
	#):
	#	switch_to("AirEntryState")
		
	
	if (start_pos.distance_to(player.global_position) >= player.dash_distance
		or player.is_on_wall()
	):
		switch_to("AirEntryState")
