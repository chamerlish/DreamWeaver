extends Node
class_name EventHandler

signal eventTriggered

func _ready() -> void:
	eventTriggered.connect(_on_event_triggered)

func _on_event_triggered() -> void:
	pass
