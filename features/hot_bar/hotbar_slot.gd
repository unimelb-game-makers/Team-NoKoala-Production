class_name HotBarSlot
extends Button

@onready var label: Label = $Label
@onready var qty_label: Label = $QtyLabel
@onready var sprite: Sprite2D = $Sprite2D
@onready var selection: Control = $Selection

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
	if item == null:
		return false
	return item.stack.is_full()

func fill_slot(new_item: FactoryItem) -> int:
	if item != null and item.stack.can_merge_with(new_item.stack):
		var left_over = item.stack.merge_from(new_item.stack)
		quantity = item.stack.quantity
		return left_over
	
	item = new_item
	sprite.texture = new_item.sprite.texture
	
	# only connect now that item exists
	item.stack.quantity_changed.connect(update_quantity)
	update_quantity()
	return 0

func update_quantity() -> void:
	quantity = item.stack.quantity if item else 0
