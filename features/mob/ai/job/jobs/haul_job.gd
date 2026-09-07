class_name HaulJob
extends Job

var item: FactoryItem
var storage: Vector3i


const JOB_TYPE := &"haul"


func _init(p_item: FactoryItem, p_storage: Vector3i) -> void:
	item = p_item
	storage = p_storage


func create_driver(consumer: JobConsumer) -> JobDriver:
	return HaulJobDriver.new(consumer, self)
