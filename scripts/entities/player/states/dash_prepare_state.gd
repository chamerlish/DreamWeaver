class_name DashPrepareState
extends PlayerState

var start_pos: Vector3
var end_pos: Vector3
var dash_dir: float

var mesh: MeshInstance3D
var material: Material
var default_color: Color
var color_tween: Tween

func _enter(_previous_state: State) -> void:
	mesh = player.get_node("Mesh")
	material = mesh.material_override
	default_color = material.albedo_color

	# Safety: ensure material exists
	if material == null:
		material = mesh.get_active_material(0)

	# Optional but recommended (avoid shared material issues)
	material = material.duplicate()
	mesh.material_override = material

	

	color_tween = create_tween()
	color_tween.tween_property(material, "albedo_color", Color.DARK_RED, player.dash_cooldown_timer.wait_time)

	player.dash_point.show()
	player.dash_line_instance.show()
	start_pos = player.global_position
	end_pos = player.dash_point.global_position
	
	player.show_dash_pos(player.dash_indicator)
	player.velocity = Vector3(player.dash_speed * dash_dir, 0.0, 0.0)
	player.dash_cooldown_timer.start()
	player.after_dash_gravity_timer.start()

func _exit(_current_state: State) -> void:
	color_tween.kill()
	color_tween = create_tween()
	color_tween.tween_property(material, "albedo_color", default_color, 1)

func _physics_update(delta: float) -> void:
	player.look_at_dir(delta)
	player.try_dash()
	player.move_and_slide()
	
	if Input.is_action_just_released("dash"):
		if player.dash_cooldown_timer.is_stopped(): 
			switch_to("DashState")
		else:
			switch_to("AirEntryState")
