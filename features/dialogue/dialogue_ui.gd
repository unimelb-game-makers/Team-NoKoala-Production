class_name DialogueUI
extends CanvasLayer

signal finished

@export var characters: Array[DialogueCharacterDefinition] = []

@onready var backdrop: Control = %Backdrop
@onready var portrait: TextureRect = %Portrait
@onready var character_label: Label = %CharacterLabel
@onready var dialogue_label: DialogueLabel = %DialogueLabel
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu
@onready var continue_hint: Label = %ContinueHint

var active := false
var _resource: DialogueResource
var _current_line: DialogueLine
var _advancing := false
var _waiting_for_input := false
var _previous_focus_owner: Control
var _characters_by_key: Dictionary[String, DialogueCharacterDefinition] = {}


func _ready() -> void:
	for character in characters:
		if character != null and not character.speaker_key.is_empty():
			_characters_by_key[character.speaker_key] = character
	backdrop.gui_input.connect(_on_backdrop_gui_input)
	dialogue_label.finished_typing.connect(_on_finished_typing)
	responses_menu.response_selected.connect(_on_response_selected)


func start_dialogue(resource: DialogueResource, cue: String = "") -> bool:
	if active or resource == null or resource.lines.is_empty():
		return false

	_resource = resource
	_current_line = null
	_advancing = false
	_waiting_for_input = false
	active = true
	_previous_focus_owner = get_viewport().gui_get_focus_owner()
	backdrop.grab_focus()
	continue_hint.hide()
	responses_menu.hide()
	_advance(cue)
	return true


func _advance(next_id: String) -> void:
	if not active or _advancing:
		return
	_advancing = true
	_waiting_for_input = false
	continue_hint.hide()
	responses_menu.hide()
	backdrop.grab_focus()

	var line: DialogueLine = await _resource.get_next_dialogue_line(next_id)
	if not active:
		return
	_advancing = false
	if line == null:
		_finish()
		return

	_current_line = line
	_apply_character(line.character)
	dialogue_label.dialogue_line = line
	dialogue_label.type_out()


func _apply_character(speaker_key: String) -> void:
	var character: DialogueCharacterDefinition = _characters_by_key.get(speaker_key)
	var shown_name := speaker_key
	var shown_portrait: Texture2D = null
	if character != null:
		if not character.display_name.is_empty():
			shown_name = character.display_name
		shown_portrait = character.portrait

	character_label.text = tr(shown_name, "dialogue")
	character_label.visible = not shown_name.is_empty()
	portrait.texture = shown_portrait
	portrait.visible = shown_portrait != null


func _on_finished_typing() -> void:
	if not active or _current_line == null:
		return
	if _current_line.responses.is_empty():
		_waiting_for_input = true
		continue_hint.show()
	else:
		responses_menu.responses = _current_line.responses
		responses_menu.show()


func _on_response_selected(response: DialogueResponse) -> void:
	if active and not _advancing and responses_menu.visible and response != null:
		_advance(response.next_id)


func _on_backdrop_gui_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed(&"ui_accept") and not event.is_echo() and not responses_menu.visible:
		_handle_advance_input()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_advance_input()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not active or event.is_echo() or not event.is_action_pressed(&"ui_accept"):
		return
	if _current_line != null and not responses_menu.visible:
		_handle_advance_input()
		get_viewport().set_input_as_handled()


func _handle_advance_input() -> void:
	if not active or _advancing or _current_line == null:
		return
	if dialogue_label.is_typing:
		dialogue_label.skip_typing()
	elif _waiting_for_input:
		_advance(_current_line.next_id)


func _finish() -> void:
	active = false
	_resource = null
	_current_line = null
	_advancing = false
	_waiting_for_input = false
	dialogue_label.dialogue_line = null
	responses_menu.responses = []
	responses_menu.hide()
	continue_hint.hide()
	portrait.texture = null
	if is_instance_valid(_previous_focus_owner) and _previous_focus_owner.is_inside_tree():
		_previous_focus_owner.grab_focus()
	_previous_focus_owner = null
	finished.emit()
