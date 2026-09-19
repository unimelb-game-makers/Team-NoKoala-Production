class_name WorkerCapability
extends Resource

@export var allowed_work_types: Array[WorkType.Value] = []


func can_perform(work_type: RecipeWorkRequirement.WorkType) -> bool:
	for allowed_type in allowed_work_types:
		if allowed_type != null and allowed_type == work_type:
			return true
	return false
