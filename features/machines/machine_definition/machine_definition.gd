@abstract
class_name MachineDefinition
extends Resource


@export var cells: Array[MachineCellDefinition] = []

@abstract func accepts_input(
	port_id: StringName, 
	processable_definition: ProcessableDefinition,
) -> bool

