class_name Hotbar
extends Control

@export var slots: Array[HotbarSlot]

var inventory: Inventory = null


func _ready() -> void:
	for index in slots.size():
		slots[index].selected.connect(_on_slot_selected.bind(index))
	_refresh()


func bind_inventory(p_inventory: Inventory) -> void:
	if inventory != null:
		inventory.slot_changed.disconnect(_on_slot_changed)
		inventory.selected_index_changed.disconnect(_on_selected_index_changed)
	inventory = p_inventory
	if inventory != null:
		inventory.slot_changed.connect(_on_slot_changed)
		inventory.selected_index_changed.connect(_on_selected_index_changed)
	# slots may not be ready yet when bound from a sibling's _ready
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	for index in slots.size():
		var slot := slots[index]
		slot.visible = inventory != null and index < inventory.size()
		if not slot.visible:
			continue
		slot.display(inventory.get_slot(index))
		slot.selection.visible = index == inventory.selected_index


func _on_slot_selected(index: int) -> void:
	if inventory != null:
		inventory.select(index)


func _on_slot_changed(index: int) -> void:
	if index < slots.size() and is_node_ready():
		slots[index].display(inventory.get_slot(index))


func _on_selected_index_changed(previous: int, current: int) -> void:
	if not is_node_ready():
		return
	if previous < slots.size():
		slots[previous].selection.visible = false
	if current < slots.size():
		slots[current].selection.visible = true
