class_name WanderJob
extends Job

var radius: float


func job_type() -> StringName:
	return "wander"


func _init(p_radius: float) -> void:
	radius = p_radius


func create_driver(consumer: JobConsumer) -> JobDriver:
	return WanderJobDriver.new(consumer, self)
