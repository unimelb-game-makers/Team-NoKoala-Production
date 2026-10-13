class_name MapAreaTrigger
extends Area3D

signal region_entered(region_id: StringName)

@export var region_id: StringName
var _triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if _triggered or not body is Player:
		return
	_triggered = true
	region_entered.emit(region_id)
