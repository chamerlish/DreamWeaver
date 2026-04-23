extends Area3D
class_name Checkpoint

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node3D):
	if "Player" in body.get_groups():
		body.current_checkpoint = self
		print(body.current_checkpoint)
