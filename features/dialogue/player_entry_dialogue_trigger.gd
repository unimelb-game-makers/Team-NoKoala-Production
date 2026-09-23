class_name PlayerEntryDialogueTrigger
extends Area3D

signal dialogue_requested(cue: StringName)

@export var cue: StringName
@export var one_shot := true
@export var dialogue_coordinator: DialogueCoordinator

var _triggered := false

func configure(p_dialogue_coordinator: DialogueCoordinator):
	dialogue_coordinator = p_dialogue_coordinator

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _triggered or not body is Player:
		return
	if cue.is_empty():
		push_warning("PlayerEntryDialogueTrigger requires a cue")
		return
	if dialogue_coordinator.request_by_cue(cue):
		_triggered = one_shot
	