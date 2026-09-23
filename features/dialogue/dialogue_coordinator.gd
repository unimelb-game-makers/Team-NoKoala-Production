class_name DialogueCoordinator
extends Node

signal dialogue_requested(entry: DialogueEntry)


@export var dialogues: Array[DialogueResource]


func request_by_cue(cue: StringName):

	for dialogue : DialogueResource in dialogues:
		if dialogue.has_title("cue"):
			dialogue_requested.emit(DialogueEntry.new(dialogue, cue, self))
		return

	push_warning("Unknown dialogue cue: %s" % cue)
