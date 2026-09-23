@tool
class_name MachineCellDefinition
extends Resource

enum Role {
	INPUT,
	OUTPUT,
	STRUCTURE,
	WORK,
}

@export var port_id: StringName = 'default'
@export var role: Role
@export var local_cell_offset: Vector3i:
	set(value):
		if local_cell_offset == value:
			return
		local_cell_offset = value
		emit_changed()

@export var can_overlap: bool = false:
	set(value):
		if can_overlap == value:
			return
		can_overlap = value
		emit_changed()
