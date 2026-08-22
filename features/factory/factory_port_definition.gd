class_name FactoryPortDefinition
extends Resource

enum Role {
	INPUT,
	OUTPUT,
}

@export var port_id: StringName
@export var role: Role
@export var local_cell_offset: Vector3i

