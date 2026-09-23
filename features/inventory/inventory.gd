class_name Inventory
extends RefCounted

signal slot_changed(index: int)
signal selected_index_changed(previous: int, current: int)

var slots: Array[FactoryItem] = []
var selected_index: int = 0

# the item in the currently selected slot
var hand_slot: FactoryItem:
	get:
		return slots[selected_index]
	set(value):
		set_slot(selected_index, value)


func _init(slot_count: int = 1) -> void:
	slots.resize(maxi(slot_count, 1))


func size() -> int:
	return slots.size()


func get_slot(index: int) -> FactoryItem:
	if index < 0 or index >= slots.size():
		return null
	return slots[index]


func set_slot(index: int, item: FactoryItem) -> void:
	if index < 0 or index >= slots.size():
		return
	slots[index] = item
	slot_changed.emit(index)


func select(index: int) -> void:
	index = clampi(index, 0, slots.size() - 1)
	if index == selected_index:
		return
	var previous := selected_index
	selected_index = index
	selected_index_changed.emit(previous, selected_index)


func is_full() -> bool:
	for item in slots:
		if item == null or not item.stack.is_full():
			return false
	return true


# merges the item into compatible stacks (selected slot first), then places
# any leftover into an empty slot (selected slot first).
# returns the slot index the item ended up in, or -1 if there was no room.
# if the item's stack was fully absorbed, the caller owns freeing the item.
func try_add(item: FactoryItem) -> int:
	if item == null or item.stack == null:
		return -1

	var merged_index := -1
	for index in _slot_order():
		var slot_item := slots[index]
		if slot_item == null or slot_item == item or slot_item.stack == null:
			continue
		if not slot_item.stack.can_merge_with(item.stack):
			continue
		slot_item.stack.merge_from(item.stack)
		merged_index = index
		if item.stack.is_empty():
			return merged_index

	for index in _slot_order():
		if slots[index] == null:
			set_slot(index, item)
			return index

	return merged_index


func _slot_order() -> Array[int]:
	var order: Array[int] = [selected_index]
	for index in slots.size():
		if index != selected_index:
			order.append(index)
	return order
