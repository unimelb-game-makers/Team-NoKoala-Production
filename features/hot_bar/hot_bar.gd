class_name HotBar
extends Control

var selected_slot: HotBarSlot = null
@export var slots: Array[HotBarSlot]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	selected_slot = slots[0]

func _is_full() -> bool:
	for slot in slots:
		if !slot.is_full():
			return false
	
	return true

func try_pickup(item: FactoryItem) -> bool:
	if _is_full():
		return false
	
	print("try pickup")
	
	var slot = _get_next_available_slot()
	print(slot)
	slot.sprite.texture = item.sprite.texture
	slot.quantity = item.stack.quantity # TO DO: fix this to merge quantities
	
	return true
	
func _get_next_available_slot() -> HotBarSlot:
	for slot in slots:
		if !slot.is_full():
			return slot
	
	return null
	
func try_putdown() -> bool:
	return true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
# on pick up: check if free slot
# if yes: populate next free slot with item
# on drop: check which slot is selected and drop only this
