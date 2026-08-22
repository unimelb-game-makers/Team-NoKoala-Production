class_name MachineBlockDefinition
extends Resource

enum Role {
	INPUT,
	OUTPUT,
	STRUCTURE,
}

@export var port_id: StringName = 'default'
@export var role: Role
@export var local_cell_offset: Vector3i
