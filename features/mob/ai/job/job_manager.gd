class_name JobManager
extends Node

static var providers: Array[JobProvider] = []
@export var world_jobs: WorldJobs

func _ready() -> void:
	register_provider(HaulJobProvider.new(self))


static func register_provider(provider: JobProvider) -> void:
	providers.append(provider)


static func find_best_job(consumer: JobConsumer) -> Job:
	var sorted_providers: Array[JobProvider] = providers.duplicate()

	sorted_providers.sort_custom(
		func(a: JobProvider, b: JobProvider) -> bool:
			var a_priority := get_consumer_priority(consumer, a.job_type())
			var b_priority := get_consumer_priority(consumer, b.job_type())

			return a_priority < b_priority
	)

	for provider in sorted_providers:
		var priority := get_consumer_priority(consumer, provider.job_type())

		if priority <= 0:
			continue

		var job := provider.find_job(consumer)

		if job:
			return job

	return null


static func get_consumer_priority(
	consumer: JobConsumer,
	job_type: StringName
) -> int:
	return consumer.job_priorities.get(job_type, 0)
