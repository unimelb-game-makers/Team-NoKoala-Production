@tool
class_name ResourceAreaMachineAssembly
extends MachineAssembly

@export_tool_button("Delete Resource Area", "Callable")
var delete_resource_area_button = delete_self

func delete_self() -> void:
	queue_free()
	if block.block_data != null:
		var grid: Grid = get_parent()
		grid.remove_block(block)
