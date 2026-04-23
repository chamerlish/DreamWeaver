class_name JumpState
extends PlayerState

func _enter(_previous_state: State) -> void:
	#player.stop_jump_timers()
	pass


func _physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_movement(delta)
	player.look_at_dir()
	player.show_landing_pos(player.floor_indicator)
	# player.try_wall_jump()
	# player.try_coyote_wall_jump()
	# player.try_wall_jump_buffer_timer()
	player.try_dash()
	player.try_jump()
	# player.try_corner_correction(delta)
	
	player.move_and_slide()
	
	if player.velocity.y >= 0:
		switch_to("FallState")
