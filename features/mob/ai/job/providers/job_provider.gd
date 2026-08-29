@abstract
class_name JobProvider

var job_manager: JobManager
var base_priority: float = 0.0


func _init(p_job_manager: JobManager) -> void:
	job_manager = p_job_manager


@abstract
func job_type() -> StringName


@abstract
func find_job(_consumer: JobConsumer) -> Job
