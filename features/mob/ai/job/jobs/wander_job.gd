class_name WanderJob
extends Job

const JOB_TYPE := &"wander"

var radius: float


func job_type() -> StringName:
	return JOB_TYPE


func _init(p_radius: float) -> void:
	radius = p_radius


func create_driver(consumer: JobConsumer) -> JobDriver:
	return WanderJobDriver.new(consumer, self)
