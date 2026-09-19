class_name HotBarSlot
extends Button

@onready var label: Label = $Label
@onready var qty_label: Label = $QtyLabel
@onready var sprite: Sprite2D = $Sprite2D

signal selected

var quantity: int = 0:
	set(value):
		quantity = value
		if qty_label:
			qty_label.text = "qty: " + str(quantity) if quantity > 0 else ""

var item: FactoryItem = null

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

func fill_slot(new_item: FactoryItem) -> void:
	item = new_item
	sprite.texture = new_item.sprite.texture
	quantity = new_item.stack.quantity # TO DO: fix this to merge quantities
