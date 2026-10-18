class_name DialogueCoordinator
extends Node

signal dialogue_requested(entry: DialogueEntry)
signal dialogue_finished(cue: StringName)


@export var dialogues: Array[DialogueResource]


func request_by_cue(cue: StringName) -> bool:

	for dialogue : DialogueResource in dialogues:
		if dialogue != null and dialogue.cues.has(cue):
			dialogue_requested.emit(DialogueEntry.new(dialogue, cue, self))
			return true

	push_warning("Unknown dialogue cue: %s" % cue)
	return false


## Called by the UI that played a requested dialogue once it ends.
func notify_finished(cue: StringName) -> void:
	dialogue_finished.emit(cue)
