class_name RunInParallel
extends CompositeNode

var _completed: Array[BehaviourNode] = []

func _on_process(brain: Brain, delta: float) -> int:
	for child in children:
		if child in _completed:
			continue

		match brain.execute_behaviour_node(child, delta):
			Status.SUCCESS:
				_completed.append(child)

			Status.FAILURE:
				return Status.FAILURE

			Status.RUNNING:
				pass

	if _completed.size() == children.size():
		return Status.SUCCESS

	return Status.RUNNING
