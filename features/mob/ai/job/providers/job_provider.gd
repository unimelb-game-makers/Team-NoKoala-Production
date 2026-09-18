class_name JobProvider
extends Node

var _active := false
var _queue := JobQueue.new()
var _active_jobs: Dictionary[JobRequest, Dictionary] = {}
var _job_board: JobBoard



func _exit_tree() -> void:
	deactivate()


func activate() -> void:
	if _active:
		return
	_active = true
	_job_board.register(self)


func deactivate() -> void:
	if not _active:
		return
	_active = false
	for entry in get_active_assignments():
		var consumer := entry.consumer as JobConsumer
		if consumer != null and is_instance_valid(consumer):
			consumer.interrupt_job()
	_active_jobs.clear()
	if _job_board != null:
		_job_board.unregister(self)


func enqueue(request: JobRequest) -> void:
	_queue.enqueue(request)


func remove(request: JobRequest) -> bool:
	return _queue.remove(request)


func get_requests() -> Array[JobRequest]:
	return _queue.get_requests()


func get_available_requests(consumer: JobConsumer) -> Array[JobRequest]:
	return _queue.get_available_requests(consumer)


func try_claim(request: JobRequest, consumer: JobConsumer) -> Job:
	return _track_claim(request, consumer, _queue.try_claim(request, consumer))


func try_claim_item(
	request: JobRequest,
	consumer: JobConsumer,
	item: FactoryItem,
) -> Job:
	return _track_claim(
		request,
		consumer,
		_queue.try_claim_item(request, consumer, item),
	)


func _track_claim(
	request: JobRequest,
	consumer: JobConsumer,
	job: Job,
) -> Job:
	if job != null:
		_active_jobs[request] = {"consumer": consumer, "job": job}
	return job


func get_active_assignments() -> Array[Dictionary]:
	_prune_active_assignments()
	var result: Array[Dictionary] = []
	for request in _active_jobs:
		var stored: Dictionary = _active_jobs[request]
		result.append({
			"request": request,
			"consumer": stored.consumer,
			"job": stored.job,
		})
	return result


func get_active_consumer(request: JobRequest) -> JobConsumer:
	_prune_active_assignments()
	if not _active_jobs.has(request):
		return null
	return _active_jobs[request].consumer as JobConsumer


func get_active_job(request: JobRequest) -> Job:
	_prune_active_assignments()
	if not _active_jobs.has(request):
		return null
	return _active_jobs[request].job as Job


func can_take_over(request: JobRequest, consumer: JobConsumer) -> bool:
	_prune_active_assignments()
	if (
		request == null
		or consumer == null
		or consumer.get_job_priority(request.job_type()) <= 0
		or not _active_jobs.has(request)
	):
		return false
	var entry: Dictionary = _active_jobs[request]
	return request.can_take_over(consumer, entry.job, entry.consumer)


func complete_request(request: JobRequest, consumer: JobConsumer) -> void:
	if _owns_assignment(request, consumer):
		_active_jobs.erase(request)


func cancel_request(request: JobRequest, consumer: JobConsumer) -> void:
	if not _owns_assignment(request, consumer):
		return
	_active_jobs.erase(request)
	request.state = JobRequest.State.AVAILABLE
	if _active:
		enqueue(request)


func _owns_assignment(request: JobRequest, consumer: JobConsumer) -> bool:
	return (
		_active_jobs.has(request)
		and _active_jobs[request].consumer == consumer
	)


func _prune_active_assignments() -> void:
	for request in _active_jobs.keys():
		var consumer := _active_jobs[request].consumer as JobConsumer
		if consumer == null or not is_instance_valid(consumer):
			_active_jobs.erase(request)
			request.state = JobRequest.State.AVAILABLE
			if _active:
				enqueue(request)
