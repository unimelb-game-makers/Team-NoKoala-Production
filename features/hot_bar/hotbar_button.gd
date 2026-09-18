extends Button

@onready var label: Label = $Label

func _ready() -> void:
	var event: InputEvent = shortcut.events[0]
	label.text = event.as_text()
	pressed.connect(_slot_selected)

func _slot_selected() -> void:
	print("slot selected")
