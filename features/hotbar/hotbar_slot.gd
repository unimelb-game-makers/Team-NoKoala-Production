class_name HotbarSlot
extends Button

@onready var label: Label = $Label
@onready var qty_label: Label = $QtyLabel
@onready var sprite: Sprite2D = $Sprite2D
@onready var selection: Control = $Selection

signal selected

var _item: FactoryItem = null

func _ready() -> void:
	var event: InputEvent = shortcut.events[0]
	label.text = event.as_text()
	pressed.connect(_slot_selected)

func _slot_selected() -> void:
	selected.emit()

func display(item: FactoryItem) -> void:
	if _has_stack(_item) and _item.stack.quantity_changed.is_connected(_update_quantity):
		_item.stack.quantity_changed.disconnect(_update_quantity)

	_item = item
	sprite.texture = _item.sprite.texture if _has_stack(_item) else null
	if _has_stack(_item):
		_item.stack.quantity_changed.connect(_update_quantity)
	_update_quantity()

func _update_quantity() -> void:
	var quantity := _item.stack.quantity if _has_stack(_item) else 0
	qty_label.text = "qty: " + str(quantity) if quantity > 0 else ""

func _has_stack(item: FactoryItem) -> bool:
	return is_instance_valid(item) and item.stack != null
