class_name HotBar
extends Control

var selected_slot: HotBarSlot = null
@export var slots: Array[HotBarSlot]

signal selected_item_changed(item: FactoryItem)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for slot in slots:
		slot.selected.connect(_on_slot_selected.bind(slot))
	if slots.size() > 0:
		selected_slot = slots[0]
		selected_slot.selection.visible = true
		selected_item_changed.emit(selected_slot.item)
	
func _on_slot_selected(slot: HotBarSlot) -> void:
	if selected_slot == slot:
		return
	selected_slot.selection.visible = false
	selected_slot = slot
	selected_slot.selection.visible = true
	selected_item_changed.emit(selected_slot.item)

func _is_full() -> bool:
	for slot in slots:
		if !slot.is_full():
			return false
	
	return true

func try_pickup(item: FactoryItem) -> bool:
	if _is_full() or item == null:
		print("hot bar full")
		return false
	
	print("hot bar not full")
	var slot = _get_next_available_slot()
	if slot != null:
		if slot.fill_slot(item) > 0:
			slot = _get_next_available_slot() # try filling the next
		else:
			return true
		if slot != null:
			if slot.fill_slot(item) == 0:
				return true
		
	
	if slot == selected_slot:
		selected_item_changed.emit(slot.item)
		return true
	
	return false # filled as much as we can or not possible
	
func _get_next_available_slot() -> HotBarSlot:
	for slot in slots:
		if !slot.is_full():
			return slot
	
	return null
	
func try_drop(item: FactoryItem) -> bool:
	if selected_slot.item == null:
		return false
	
	selected_slot.item = null
	selected_slot.quantity = 0
	selected_slot.sprite.texture = null
	selected_item_changed.emit(null)
	return true
	
# on pick up: check if free slot
# if yes: populate next free slot with item
# on drop: check which slot is selected and drop only this
