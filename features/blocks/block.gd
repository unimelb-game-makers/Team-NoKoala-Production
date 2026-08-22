@abstract
class_name Block
extends Node3D

@export var block_data: BlockData

func switch_rotation() -> void:
	block_data.switch_rotation()
	rotation_degrees.y = block_data.block_rotation
