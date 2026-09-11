class_name JobProvider
extends Node

var _active := false
var _queue := JobQueue.new()


func _exit_tree() -> void:
	deactivate()


func activate() -> void:
	if _active:
		return
	_active = true
	JobBoard.register(self)


func deactivate() -> void:
	if not _active:
		return
	_active = false
	JobBoard.unregister(self)


func enqueue(request: JobRequest) -> void:
	_queue.enqueue(request)


func remove(request: JobRequest) -> bool:
	return _queue.remove(request)


func get_requests() -> Array[JobRequest]:
	return _queue.get_requests()


func get_available_requests(consumer: JobConsumer) -> Array[JobRequest]:
	return _queue.get_available_requests(consumer)


func try_claim(request: JobRequest, consumer: JobConsumer) -> Job:
	return _queue.try_claim(request, consumer)
