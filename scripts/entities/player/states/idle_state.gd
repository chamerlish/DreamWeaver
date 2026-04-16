class_name IdleState
extends PlayerState

func _physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_movement(delta, player.running_acc_time, player.running_dec_time)
	player.try_jump()
	player.try_dash()
	if player.get_input_vector() == Vector2.ZERO:
		player.apply_friction(delta, 20.0) # tweak friction strength
	else:
		player.apply_movement(delta, 0.2, 0.3)
	player.move_and_slide()
	
	if not player.is_on_floor():
		switch_to("AirEntryState")
	elif player.velocity.x:
		switch_to("RunState")
