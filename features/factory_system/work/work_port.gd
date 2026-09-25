class_name WorkPort
extends RefCounted

signal enabled_changed(port: WorkPort, enabled: bool)
signal allocation_changed(port: WorkPort, worker: WorkerCapability)

var port_id: StringName
var work_type: WorkType.Value
var cells: Array[Vector3i] = []
var worker: WorkerCapability
var enabled := true:
	set(value):
		if enabled == value:
			return
		enabled = value
		if not enabled and worker != null:
			worker = null
			allocation_changed.emit(self, worker)
		enabled_changed.emit(self, enabled)


func _init(
	p_port_id: StringName,
	p_work_type: WorkType.Value,
	p_cells: Array[Vector3i],
) -> void:
	port_id = p_port_id
	work_type = p_work_type
	cells = p_cells.duplicate()


func contains_cell(cell: Vector3i) -> bool:
	return cells.has(cell)


func is_ready() -> bool:
	return enabled and worker != null and worker.can_perform(work_type)


func toggle_enabled() -> bool:
	enabled = not enabled
	return enabled


func try_allocate(capability: WorkerCapability) -> bool:
	if not enabled or worker != null or capability == null:
		return false
	if not capability.can_perform(work_type):
		return false
	worker = capability
	allocation_changed.emit(self, worker)
	return true


func try_release(capability: WorkerCapability) -> bool:
	if capability == null or worker != capability:
		return false
	worker = null
	allocation_changed.emit(self, worker)
	return true


func is_allocated_to(capability: WorkerCapability) -> bool:
	return capability != null and worker == capability
