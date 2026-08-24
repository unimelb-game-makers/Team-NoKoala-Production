class_name Repeat
extends ModifierNode

var _last_child_status: Status

func _on_start(brain: Brain) -> Status:
	_last_child_status = child.start(brain)
	return Status.RUNNING

func _on_process(brain: Brain, delta: float) -> Status:
	match _last_child_status:
		Status.RUNNING:
			_last_child_status = child.process(brain, delta)
		_:
			_last_child_status = child.start(brain)
	return Status.RUNNING
