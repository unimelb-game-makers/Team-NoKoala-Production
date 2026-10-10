class_name DialogueFinishedCondition
extends TutorialCondition

## Satisfied when the dialogue with this cue finishes. An empty cue matches any dialogue.
@export var cue: StringName

var _coordinator: DialogueCoordinator


func start(ctx: TutorialContext) -> void:
	_coordinator = ctx.dialogue_coordinator
	_coordinator.dialogue_finished.connect(_on_dialogue_finished)


func stop() -> void:
	if _coordinator != null and _coordinator.dialogue_finished.is_connected(_on_dialogue_finished):
		_coordinator.dialogue_finished.disconnect(_on_dialogue_finished)
	_coordinator = null


func _on_dialogue_finished(finished_cue: StringName) -> void:
	if cue.is_empty() or finished_cue == cue:
		satisfied.emit()
