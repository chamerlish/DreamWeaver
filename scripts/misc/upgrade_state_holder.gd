extends Area3D
class_name UpgradeStateHolder

@export var upgradeStateName: Array[StringName]
@export var upgradeStateText: String

func _on_body_entered(_body: Node3D) -> void:
	StateGlobal.stateAdded.emit(upgradeStateName)
	StateGlobal.stateAddedGui.emit(upgradeStateText)
	_destroy()

func _destroy():
	queue_free()
