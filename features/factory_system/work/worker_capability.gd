class_name WorkerCapability
extends Resource

@export var allowed_work_types: Array[WorkType.Value] = []


func can_perform(work_type: WorkType.Value) -> bool:
	for allowed_type in allowed_work_types:
		if allowed_type != null and allowed_type == work_type:
			return true
	return false
	
func change_work_type(type: WorkType.Value):
	if allowed_work_types.has(type):
		allowed_work_types.erase(type)
	else:
		allowed_work_types.append(type)
