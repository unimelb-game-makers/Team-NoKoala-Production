class_name DialogueEntry

var dialogue: DialogueResource
var cue: StringName
var from: DialogueCoordinator

func _init(p_dialogue: DialogueResource, p_cue: StringName, p_from: DialogueCoordinator) -> void:
    dialogue = p_dialogue
    cue = p_cue
    from = p_from