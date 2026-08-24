@abstract
class_name Sensor
extends Resource

func _init():
	resource_local_to_scene = true

func start(brain: Brain) -> void:
	_on_start(brain)

@abstract
func _on_start(brain: Brain) -> void

func process(brain: Brain, delta: float) -> void:
	_on_process(brain, delta)

@abstract
func _on_process(brain: Brain, delta: float) -> void
