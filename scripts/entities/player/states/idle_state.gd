class_name IdleState
extends PlayerState

func _physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_movement(delta)
	player.look_at_dir()
	player.try_jump()
	player.try_dash()

	player.move_and_slide()
	
	if not player.is_on_floor():
		switch_to("AirEntryState")
	elif player.velocity.x:
		switch_to("RunState")
