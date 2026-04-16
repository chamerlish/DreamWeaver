class_name RunState
extends PlayerState

func _physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.try_jump()
	player.try_dash()
	if player.get_input_vector() == Vector2.ZERO:
		player.apply_friction(delta, 20.0) 
	else:
		player.apply_movement(delta, player.running_acc_time, player.running_dec_time)
	
	player.move_and_slide()
	
	if not player.is_on_floor():
		switch_to("AirEntryState")
	elif not player.velocity.x and not player.get_input_vector().x:
		switch_to("IdleState")
