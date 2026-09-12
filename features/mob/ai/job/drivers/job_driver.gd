@abstract
class_name JobDriver

enum Status {
	RUNNING,
	SUCCESS,
	FAILURE,
}

var consumer: JobConsumer
var job: Job


func _init(p_consumer: JobConsumer, p_job: Job) -> void:
	consumer = p_consumer
	job = p_job


func start() -> Status:
	return Status.RUNNING


func tick(_delta: float) -> Status:
	return Status.SUCCESS
