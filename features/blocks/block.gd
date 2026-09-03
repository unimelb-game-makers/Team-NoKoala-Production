class_name Block
extends Node3D

@export var block_data: BlockData
@export var transform_root: Node3D

func get_transform_root() -> Node3D:
	return transform_root if transform_root != null else self

func switch_rotation() -> void:
	block_data.switch_rotation()
	_sync_rotation_visual()

func set_rotation_data(value) -> void:
	block_data.block_rotation = value
	_sync_rotation_visual()

func _sync_rotation_visual() -> void:
	get_transform_root().rotation_degrees.y = block_data.block_rotation
