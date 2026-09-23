class_name UIRoot
extends Node


@export var faith_progress_bar: FaithProgressBar
@export var dialogue_ui: DialogueUI

var _context: WorldContext


func _ready() -> void:
	assert(faith_progress_bar != null, "UIRoot requires a FaithProgressBar")
	assert(dialogue_ui != null, "UIRoot requires a DialogueUI")
	dialogue_ui.hide()
	dialogue_ui.finished.connect(_on_dialogue_finished)

func bind_world(context: WorldContext) -> void:
	if _context == context:
		return

	unbind_world()
	_context = context
	faith_progress_bar.bind(context.faith)
	context.dialogue_coordinator.dialogue_requested.connect(_on_dialogue_requested)


func unbind_world() -> void:
	if faith_progress_bar != null:
		faith_progress_bar.unbind()
	_context = null


func start_dialogue(resource: DialogueResource, cue: String = "") -> bool:
	if dialogue_ui.active:
		return false
	dialogue_ui.show()
	if not dialogue_ui.start_dialogue(resource, cue):
		dialogue_ui.hide()
		return false
	return true


func is_dialogue_active() -> bool:
	return dialogue_ui.active


func _on_dialogue_requested(entry: DialogueEntry) -> void:
	start_dialogue(entry.dialogue, entry.cue)



func _on_dialogue_finished() -> void:
	dialogue_ui.hide()
