class_name WorkJob
extends Job

var destination: Vector3i
var work_type: WorkType.Value
var machine: Machine


const JOB_TYPE := &"work"


func _init(
	p_work_type: WorkType.Value,
	p_destination: Vector3i,
	p_machine: Machine,
) -> void:
	work_type = p_work_type
	destination = p_destination
	machine = p_machine


func create_driver(consumer: JobConsumer) -> JobDriver:
	var driver := WorkJobDriver.new(consumer, self)
	driver.configure(consumer.movement, consumer.grid)
	return driver
