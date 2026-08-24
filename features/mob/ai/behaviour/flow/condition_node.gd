@abstract
class_name ConditionNode
extends BehaviourNode

@abstract
func _check(brain: Brain) -> bool

func _on_process(brain: Brain, _delta: float) -> int:
	if _check(brain):
		return Status.SUCCESS
	else:
		return Status.FAILURE
