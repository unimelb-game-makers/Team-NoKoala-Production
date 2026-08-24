class_name WeightedRandom
extends BehaviourNode

@export var branches: Array[RandomBranch]

var _selected_index := -1

func _on_process(brain: Brain, delta: float) -> Status:
	if branches.is_empty():
		return Status.FAILURE

	if _selected_index == -1:
		_selected_index = _pick_child()

		if _selected_index == -1:
			return Status.FAILURE

	return brain.execute_behaviour_node(branches[_selected_index].node, delta)


func _pick_child() -> int:
	var total_weight := 0.0

	for i in branches.size():
		total_weight += maxf(_weight_at(i), 0.0)

	if total_weight <= 0.0:
		return -1

	var roll := randf() * total_weight
	var accumulated := 0.0

	for i in branches.size():
		accumulated += maxf(_weight_at(i), 0.0)

		if roll < accumulated:
			return i

	# Floating-point fallback.
	return branches.size() - 1


func _weight_at(index: int) -> float:
	if index < branches.size():
		return branches[index].weight

	return 1.0