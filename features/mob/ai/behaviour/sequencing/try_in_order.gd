class_name TryInOrder
extends CompositeNode

var _index := 0

func _on_process(brain: Brain, delta: float) -> Status:
	while _index < children.size():
		var result := brain.execute_behaviour_node(children[_index], delta)

		if result == Status.RUNNING:
			return result

		if result == Status.SUCCESS:
			_index = 0
			return result

		_index += 1

	_index = 0
	return Status.FAILURE
