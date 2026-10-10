class_name AnyOfCondition
extends TutorialCondition

## Satisfied as soon as one child condition is satisfied.
@export var conditions: Array[TutorialCondition] = []

var _done := false
var _best_ratio := 0.0


func has_progress() -> bool:
	return conditions.any(func(c: TutorialCondition) -> bool: return c.has_progress())


func start(ctx: TutorialContext) -> void:
	_done = false
	_best_ratio = 0.0
	for condition in conditions:
		condition.satisfied.connect(_on_child_satisfied)
		if condition.has_progress():
			condition.progress_changed.connect(_on_child_progress)
	for condition in conditions:
		condition.start(ctx)


func stop() -> void:
	for condition in conditions:
		condition.stop()
		if condition.satisfied.is_connected(_on_child_satisfied):
			condition.satisfied.disconnect(_on_child_satisfied)
		if condition.progress_changed.is_connected(_on_child_progress):
			condition.progress_changed.disconnect(_on_child_progress)


func _on_child_progress(ratio: float) -> void:
	if ratio > _best_ratio:
		_best_ratio = ratio
		progress_changed.emit(_best_ratio)


func _on_child_satisfied() -> void:
	if _done:
		return
	_done = true
	satisfied.emit()
