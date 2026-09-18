class_name HaulJob
extends Job

var item: FactoryItem
var storage: Vector3i


const JOB_TYPE := &"haul"


func _init(p_item: FactoryItem, p_storage: Vector3i) -> void:
	item = p_item
	storage = p_storage


func create_driver(consumer: JobConsumer) -> JobDriver:
	var driver := HaulJobDriver.new(consumer, self)
	driver.configure(consumer.inventory_owner, consumer.movement, consumer.grid)
	return driver
