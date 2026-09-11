class_name JobQueue
extends RefCounted

var _requests: Array[JobRequest] = []


func enqueue(request: JobRequest) -> void:
	if request == null or _requests.has(request):
		return
	_requests.append(request)


func remove(request: JobRequest) -> bool:
	var index := _requests.find(request)
	if index == -1:
		return false
	_requests.remove_at(index)
	return true


func get_requests() -> Array[JobRequest]:
	return _requests.duplicate()


func get_available_requests(consumer: JobConsumer) -> Array[JobRequest]:
	var result: Array[JobRequest] = []
	for request in _requests:
		if consumer.get_job_priority(request.job_type()) <= 0:
			continue
		if request.can_assign(consumer):
			result.append(request)
	return result


## Claim and materialise a request as one operation. This prevents two consumers
## from creating jobs from the same queue entry.
func try_claim(request: JobRequest, consumer: JobConsumer) -> Job:
	if request == null or not _requests.has(request):
		return null
	if not request.can_assign(consumer):
		return null

	request.state = JobRequest.State.CLAIMED
	var job := request.try_create_job(consumer)
	if job == null:
		request.state = JobRequest.State.AVAILABLE
		return null

	remove(request)
	return job
