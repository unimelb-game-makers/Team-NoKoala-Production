class_name HaulJobProvider
extends JobProvider


func job_type() -> StringName:
	return HaulJob.JOB_TYPE


func find_job(consumer: JobConsumer) -> Job:
	var world_jobs := job_manager.world_jobs

	var item: FactoryItem = world_jobs.find_nearest_haulable_item(
		consumer.actor.global_position
	)
	if item == null:
		return null

	var storage = world_jobs.find_storage_for(item)
	if storage == null:
		return null

	# Reserve the item so no other mob picks the same one. The destination cell
	# is intentionally not reserved: any number of mobs may haul to it at once.
	if not ReservationManager.try_reserve(consumer, item):
		return null

	return HaulJob.new(item, storage)
