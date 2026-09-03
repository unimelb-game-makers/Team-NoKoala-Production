class_name WanderJobProvider
extends JobProvider

@export var radius: float = 10.0


func _ready() -> void:
	activate()


func job_type() -> StringName:
	return WanderJob.JOB_TYPE


## Always available: wander is the idle fallback, so it never returns null.
func find_job(_consumer: JobConsumer) -> Job:
	return WanderJob.new(radius)
