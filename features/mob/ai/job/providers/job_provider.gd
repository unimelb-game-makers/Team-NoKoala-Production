@abstract
class_name JobProvider
extends Node

var _active := false


func _exit_tree() -> void:
	deactivate()


func activate() -> void:
	if _active:
		return
	_active = true
	JobBoard.register(self)


func deactivate() -> void:
	if not _active:
		return
	_active = false
	JobBoard.unregister(self)


@abstract
func job_type() -> StringName


@abstract
func find_job(_consumer: JobConsumer) -> Job


## Orders providers of the same job type for a consumer; lower is preferred.
## Default is no preference.
func score(_consumer: JobConsumer) -> float:
	return 0.0
