class_name HotBarSlot
extends Button

@onready var label: Label = $Label
@onready var sprite: Sprite2D = $Sprite2D

var quantity: int = 0

signal selected

func _ready() -> void:
	var event: InputEvent = shortcut.events[0]
	label.text = event.as_text()
	pressed.connect(_slot_selected)

func _slot_selected() -> void:
	selected.emit()

func is_full() -> bool:
	if quantity <= 5: # TO DO: fix this to sync with ItemStack.stack_size somehow
		return false
	
	return true
