class_name WorkerCapability
extends Resource

@export var allowed_work_types: Array[WorkType.Value] = []
@export var consumes_faith: bool = true


func can_perform(work_type: WorkType.Value) -> bool:
	for allowed_type in allowed_work_types:
		if allowed_type != null and allowed_type == work_type:
			return true
	return false
