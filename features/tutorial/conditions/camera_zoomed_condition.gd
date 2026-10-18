class_name CameraZoomedCondition
extends AccumulatedProgressCondition

## Total change in camera distance, in metres, summed over zooming in and out.
@export var amount := 1.5

var _last_length: float


func _required() -> float:
	return amount


func _reset(ctx: TutorialContext) -> void:
	_last_length = ctx.camera.spring_length


func _measure(ctx: TutorialContext) -> float:
	var length := ctx.camera.spring_length
	var change := absf(length - _last_length)
	_last_length = length
	return change
