class_name CameraRotatedCondition
extends AccumulatedProgressCondition

## Total rotation in degrees, summed over both directions.
@export var degrees := 90.0

var _last_angle: float


func _required() -> float:
	return degrees


func _reset(ctx: TutorialContext) -> void:
	_last_angle = ctx.camera.rotation.y


func _measure(ctx: TutorialContext) -> float:
	var angle := ctx.camera.rotation.y
	var change := absf(rad_to_deg(angle_difference(_last_angle, angle)))
	_last_angle = angle
	return change
