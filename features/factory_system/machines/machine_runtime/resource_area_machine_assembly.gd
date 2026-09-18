@tool
class_name ResourceAreaMachineAssembly
extends MachineAssembly

@export var resource_area_definition: ResourceAreaDefinition
@export var block_data: BlockData
@export var grid: Grid

@export_tool_button("Delete Resource Area", "Callable")
var delete_resource_area_button = delete_self

func _ready() -> void:
	if resource_area_definition != null:
		$Sprite3D.texture = resource_area_definition.texture
	
	if not Engine.is_editor_hint():
		machine._processing_recipe = resource_area_definition.spawner_recipe
		machine.resource_area_definition = resource_area_definition
		block.block_data = block_data

func delete_self() -> void:
	queue_free()
	if block.block_data != null and grid != null:
		grid.remove_block(block)
