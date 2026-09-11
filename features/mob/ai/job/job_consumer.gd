class_name JobConsumer
extends Node

@export var job_priorities: Dictionary[StringName, int]

var actor: Node3D
var fixed_clock: FixedClock
var current_job: Job = null
var current_driver: JobDriver = null


func _ready() -> void:
	actor = get_parent()
	fixed_clock = get_tree().get_first_node_in_group("fixed_clock")
	fixed_clock.tick.connect(_on_tick)


func _on_tick(delta: float, _ticks_due: int, _tick_count: int) -> void:
	if current_job == null:
		find_new_job()
		return

	if current_driver:
		var result := current_driver.tick(delta)

		if result == JobDriver.Status.SUCCESS:
			finish_job()
		elif result == JobDriver.Status.FAILURE:
			cancel_job()


func find_new_job() -> void:
	var job := _select_job()

	if job == null:
		return

	current_job = job
	current_driver = job.create_driver(self)

	var result = current_driver.start()
	if result == JobDriver.Status.FAILURE:
		print("Start job driver failed: ", current_driver)
		cancel_job()


func _select_job() -> Job:
	var candidates: Array[JobCandidate] = []
	var discovery_order := 0

	for provider in JobBoard.get_providers():
		for request in provider.get_available_requests(self):
			candidates.append(
				JobCandidate.new(
					provider,
					request,
					self,
					discovery_order,
				)
			)
			discovery_order += 1

	candidates.sort_custom(
		func(a: JobCandidate, b: JobCandidate) -> bool:
			return a.is_preferred_to(b)
	)

	for candidate in candidates:
		var job := candidate.provider.try_claim(candidate.request, self)
		if job != null:
			return job

	return null


func get_job_priority(job_type: StringName) -> int:
	return job_priorities.get(job_type, 0)


func finish_job() -> void:
	_end_job()


func cancel_job() -> void:
	_end_job()


func _end_job() -> void:
	# A consumer runs one job at a time, so releasing everything it holds is
	# enough to free this job's item and destination cell.
	ReservationManager.release_all(self)
	current_job = null
	current_driver = null


func _exit_tree() -> void:
	# Despawning mid-job must not leave its targets reserved forever.
	ReservationManager.release_all(self)
