class_name IdleJobProvider
extends JobProvider

@export var radius: float = 10.0


func _ready() -> void:
	enqueue(WanderRequest.new(radius))
	activate()


func try_claim(request: JobRequest, consumer: JobConsumer) -> Job:
	var job := super(request, consumer)
	if job != null:
		# Wander is an inexhaustible idle fallback.
		enqueue(WanderRequest.new(radius))
	return job
