class_name Machine
extends Node

@export var definition: MachineDefinition
@export var faith_drain_rate: float = 0.0
@export var debug_active_indicator: Node3D

var center_position: Vector3i = Vector3i.ZERO

var is_active: bool = false

func get_input_cells() -> Array[Vector3i]:
	return _get_cells_for_role(MachineCellDefinition.Role.INPUT)

func get_output_cells() -> Array[Vector3i]:
	return _get_cells_for_role(MachineCellDefinition.Role.OUTPUT)

func get_cells_for_port(
	role: MachineCellDefinition.Role,
	port_id: StringName,
) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	var assembly := get_parent() as MachineAssembly
	for cell_definition in definition.cells:
		if (
			cell_definition.role == role
			and cell_definition.port_id == port_id
		):
			result.append(
				assembly.block.block_data.world_cell_for_offset(
					cell_definition.local_cell_offset,
				)
			)
	return result

func _get_cells_for_role(
	role: MachineCellDefinition.Role,
) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	var assembly := get_parent() as MachineAssembly
	for cell_definition in definition.cells:
		if cell_definition.role == role:
			result.append(
				assembly.block.block_data.world_cell_for_offset(
					cell_definition.local_cell_offset,
				)
			)
	return result

func register_active(drain_rate: float = 0.0) -> void:
	if not is_active:
		FaithManager._register_active(self, drain_rate)
		is_active = true
		_set_debug_indicator(true)
	
func unregister_active() -> void:
	if is_active:
		FaithManager._unregister_active(self)
		is_active = false
		_set_debug_indicator(false)
		
func _set_debug_indicator(active: bool) -> void:
	if debug_active_indicator:
		debug_active_indicator.visible = active

func factory_tick(_delta: float, _factory_manager: FactoryManager) -> void:
	pass
