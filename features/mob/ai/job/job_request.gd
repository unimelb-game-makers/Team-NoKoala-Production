@abstract
class_name JobRequest
extends RefCounted

enum State {
	AVAILABLE,
	CLAIMED,
}

var priority: float = 0.0
var state := State.AVAILABLE


@abstract
func job_type() -> StringName


func can_assign(_consumer: JobConsumer) -> bool:
	return state == State.AVAILABLE


## Lower scores are preferred among requests with the same consumer priority.
func score(_consumer: JobConsumer) -> float:
	return 0.0


## Reserve any resources needed by the job before returning it.
@abstract
func try_create_job(consumer: JobConsumer) -> Job
