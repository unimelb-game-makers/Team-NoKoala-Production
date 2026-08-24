@abstract
class_name BehaviourNode
extends Resource

enum Status {
	UNINITIALISED,
	RUNNING,
	SUCCESS,
	FAILURE,
	INTERRUPTED,
}

@export var id: StringName

var current_status: Status = Status.UNINITIALISED

func _init():
	resource_local_to_scene = true

func start(brain: Brain) -> Status:
	current_status = _on_start(brain)
	return current_status

func _on_start(_brain: Brain) -> Status:
	return Status.RUNNING

func process(brain: Brain, delta: float) -> Status:
	current_status = _on_process(brain, delta)
	return current_status

func _on_process(_brain: Brain, _delta: float) -> Status:
	return Status.SUCCESS

func end(brain: Brain) -> void:
	_on_end(brain)
	if current_status == Status.RUNNING:
		current_status = Status.INTERRUPTED

func _on_end(_brain: Brain) -> void:
	pass
