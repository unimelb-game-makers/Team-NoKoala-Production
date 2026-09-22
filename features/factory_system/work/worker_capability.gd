class_name WorkerCapability
extends Resource

@export var allowed_work_types: Array[WorkType.Value] = []


func can_perform(work_type: WorkType.Value) -> bool:
	return allowed_work_types.has(work_type)

