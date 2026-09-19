class_name InventoryOwner
extends Node

@export var pickup_distance: float = 4.0
@export var hot_bar: HotBar = null # defaults to null for npcs w/o hotbars

var actor: Node3D
var inventory: Inventory = Inventory.new()


func _ready() -> void:
	actor = get_parent()
	_bind_hot_bar()


func _process(_delta: float) -> void:
	if inventory.hand_slot != null:
		inventory.hand_slot.global_position = actor.global_position


func set_held_item(item: FactoryItem) -> void:
	if item == null:
		if inventory.hand_slot != null:
			inventory.hand_slot.sprite.visible = false
		inventory.hand_slot = null
		return
	
	inventory.hand_slot = item
	inventory.hand_slot.sprite.visible = true


func try_pick_up_item(item: FactoryItem) -> bool:
	if item == null:
		return false
	if actor.global_position.distance_to(item.global_position) > pickup_distance:
		return false
	if not item.try_claim(actor):
		return false
	
	if hot_bar != null:
		var success = hot_bar.try_pickup(item)
		if success and is_instance_valid(item) and not item.is_queued_for_deletion():
			if inventory.hand_slot != item:
				_hide_item(item)
		return success
		
	if inventory.hand_slot != null:
		if inventory.hand_slot.stack != null and item.stack != null and inventory.hand_slot.stack.can_merge_with(item.stack):
			inventory.hand_slot.stack.merge_from(item.stack)
			if item.stack.is_empty():
				item.queue_free()
			return true
		return false # holding something incompatible/full, can't pick up

	set_held_item(item)
	return true


func try_drop_held_item() -> bool:
	if inventory.hand_slot == null:
		return false

	var drop_position = actor.global_position
	drop_position.y = 0
	
	var dropped_item = inventory.hand_slot
	
	if not inventory.hand_slot.try_drop(drop_position):
		return false
	
	if is_instance_valid(dropped_item) and not dropped_item.is_queued_for_deletion():
		dropped_item.global_position = drop_position
		dropped_item.release_claim()
	
	inventory.hand_slot = null
	return true


func try_place_held_item(target_position: Vector3) -> bool:
	if inventory.hand_slot == null:
		return false
	if actor.global_position.distance_to(target_position) > pickup_distance:
		return false

	inventory.hand_slot.drop_at(target_position)
	inventory.hand_slot.global_position = target_position
	inventory.hand_slot = null
	return true
	
func _hide_item(item: FactoryItem) -> void:
	if item != null:
		item.sprite.visible = false

func _bind_hot_bar() -> void:
	if hot_bar != null:
		hot_bar.selected_item_changed.connect(_on_hot_bar_selection)

func _on_hot_bar_selection(item: FactoryItem):
	if inventory.hand_slot != null and inventory.hand_slot != item:
		_hide_item(inventory.hand_slot)
	set_held_item(item)
