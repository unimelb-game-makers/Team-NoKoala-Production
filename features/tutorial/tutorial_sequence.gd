class_name TutorialSequence
extends Resource

@export var tasks: Array[TutorialTask] = []

func get_steps() -> Array[TutorialStep]:
	var result: Array[TutorialStep] = []
	for task in tasks:
		result.append_array(task.steps)
	return result
