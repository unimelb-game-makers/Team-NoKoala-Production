@abstract
class_name Machine
extends Node

@export var definition: MachineDefinition


var center_position: Vector3i 

func _init(p_center_position: Vector3i) -> void:
	center_position = p_center_position
