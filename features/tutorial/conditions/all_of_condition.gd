class_name AllOfCondition
extends TutorialCondition

## Satisfied once every child condition has been satisfied.
@export var conditions: Array[TutorialCondition] = []

var _remaining: Dictionary[TutorialCondition, bool] = {}
var _ratios: Dictionary[TutorialCondition, float] = {}


func has_progress() -> bool:
	return conditions.any(func(c: TutorialCondition) -> bool: return c.has_progress())


func start(ctx: TutorialContext) -> void:
	_remaining.clear()
	_ratios.clear()
	for condition in conditions:
		_remaining[condition] = true
		condition.satisfied.connect(_on_child_satisfied.bind(condition))
		if condition.has_progress():
			_ratios[condition] = 0.0
			condition.progress_changed.connect(_on_child_progress.bind(condition))
	for condition in conditions:
		condition.start(ctx)


func stop() -> void:
	for condition in conditions:
		condition.stop()
		if condition.satisfied.is_connected(_on_child_satisfied.bind(condition)):
			condition.satisfied.disconnect(_on_child_satisfied.bind(condition))
		if condition.progress_changed.is_connected(_on_child_progress.bind(condition)):
			condition.progress_changed.disconnect(_on_child_progress.bind(condition))
	_remaining.clear()
	_ratios.clear()


func _on_child_progress(ratio: float, condition: TutorialCondition) -> void:
	_ratios[condition] = ratio
	var total := 0.0
	for value in _ratios.values():
		total += value
	progress_changed.emit(total / _ratios.size())


func _on_child_satisfied(condition: TutorialCondition) -> void:
	if not _remaining.erase(condition):
		return
	if _remaining.is_empty():
		satisfied.emit()
