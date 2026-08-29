@abstract
class_name Block
extends Node3D

@export var block_data: BlockData

func switch_rotation() -> void:
	block_data.switch_rotation()
	rotation_degrees.y = block_data.block_rotation

func set_rotation_data(value) -> void:
	block_data.block_rotation = value
	_sync_rotation_visual()

func _sync_rotation_visual() -> void:
	rotation_degrees.y = block_data.block_rotation
