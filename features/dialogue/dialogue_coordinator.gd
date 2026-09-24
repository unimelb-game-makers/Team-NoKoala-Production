class_name DialogueCoordinator
extends Node

signal dialogue_requested(entry: DialogueEntry)


@export var dialogues: Array[DialogueResource]


func request_by_cue(cue: StringName) -> bool:

	for dialogue : DialogueResource in dialogues:
		if dialogue != null and dialogue.cues.has(cue):
			dialogue_requested.emit(DialogueEntry.new(dialogue, cue, self))
			return true

	push_warning("Unknown dialogue cue: %s" % cue)
	return false
