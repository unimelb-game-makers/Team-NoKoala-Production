class_name JobCandidate
extends RefCounted

var provider: JobProvider
var request: JobRequest
var consumer_priority: int
var request_priority: float
var score: float
var discovery_order: int


func _init(
	p_provider: JobProvider,
	p_request: JobRequest,
	p_consumer: JobConsumer,
	p_discovery_order: int,
) -> void:
	provider = p_provider
	request = p_request
	consumer_priority = p_consumer.get_job_priority(request.job_type())
	request_priority = request.priority
	score = request.score(p_consumer)
	discovery_order = p_discovery_order


func is_preferred_to(other: JobCandidate) -> bool:
	if consumer_priority != other.consumer_priority:
		return consumer_priority > other.consumer_priority
	if request_priority != other.request_priority:
		return request_priority > other.request_priority
	if score != other.score:
		return score < other.score
	return discovery_order < other.discovery_order
