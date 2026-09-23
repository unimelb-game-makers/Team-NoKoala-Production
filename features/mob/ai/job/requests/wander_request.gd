class_name WanderRequest
extends JobRequest

var radius: float


func _init(p_radius: float) -> void:
	radius = p_radius


func job_type() -> StringName:
	return WanderJob.JOB_TYPE


func equals(other: JobRequest) -> bool:
	var wander := other as WanderRequest
	return wander != null and wander.radius == radius


func try_create_job(_consumer: JobConsumer) -> Job:
	return WanderJob.new(radius)
