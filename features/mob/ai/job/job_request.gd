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


## Read-only preview used by job discovery and UI. Claiming remains the final
## authority because world state may change after this check.
func is_actionable(consumer: JobConsumer) -> bool:
	return can_assign(consumer)


## Whether an active job can currently be transferred to another consumer.
func can_take_over(
	_consumer: JobConsumer,
	_job: Job,
	current_consumer: JobConsumer,
) -> bool:
	return current_consumer != null and is_instance_valid(current_consumer)


## Lower scores are preferred among requests with the same consumer priority.
func score(_consumer: JobConsumer) -> float:
	return 0.0


## Reserve any resources needed by the job before returning it.
@abstract
func try_create_job(consumer: JobConsumer) -> Job
