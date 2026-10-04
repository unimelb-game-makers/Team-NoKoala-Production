class_name DistanceMovedCondition
extends AccumulatedProgressCondition

## Single-tick moves larger than this (teleports, respawns) are not counted.
const MAX_STEP_DISTANCE := 2.0

## Horizontal distance in metres the player has to travel.
@export var distance := 10.0

var _last_position: Vector3


func _required() -> float:
	return distance


func _reset(ctx: TutorialContext) -> void:
	_last_position = ctx.player.global_position


func _measure(ctx: TutorialContext) -> float:
	var position := ctx.player.global_position
	var step := Vector2(position.x - _last_position.x, position.z - _last_position.z).length()
	_last_position = position
	return 0.0 if step > MAX_STEP_DISTANCE else step
