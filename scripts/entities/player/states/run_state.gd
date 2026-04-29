class_name RunState
extends PlayerState


func _physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.try_jump()
	player.try_dash()

	player.apply_movement(delta)
	player.look_at_dir(delta)
	
	player.move_and_slide()
	
	if not player.is_on_floor():
		switch_to("AirEntryState")
	elif not player.velocity.x and not player.get_input_vector().x:
		switch_to("IdleState")
