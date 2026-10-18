class_name GameUI
extends Node


@export var dialogue_ui: DialogueUI

var _context: WorldContext
var _requested_cue: StringName


func _ready() -> void:
	assert(dialogue_ui != null, "GameUI requires a DialogueUI")
	dialogue_ui.hide()
	dialogue_ui.finished.connect(_on_dialogue_finished)


func bind_world(context: WorldContext) -> void:
	if _context == context:
		return

	unbind_world()
	_context = context
	context.dialogue_coordinator.dialogue_requested.connect(_on_dialogue_requested)


func unbind_world() -> void:
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
	if start_dialogue(entry.dialogue, entry.cue):
		_requested_cue = entry.cue


func _on_dialogue_finished() -> void:
	dialogue_ui.hide()
	var cue := _requested_cue
	_requested_cue = &""
	if _context != null and not cue.is_empty():
		_context.dialogue_coordinator.notify_finished(cue)
