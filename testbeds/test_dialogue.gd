extends Control
@export var dialgue_ui: DialogueUI
@export var demo_dialogue: DialogueResource

func _ready() -> void:
	dialgue_ui.hide()
	%StartButton.pressed.connect(_on_start_button_pressed)


func _on_start_button_pressed() -> void:
	dialgue_ui.show()
	dialgue_ui.start_dialogue(demo_dialogue, "start")
