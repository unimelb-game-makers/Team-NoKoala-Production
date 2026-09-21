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
		inventory.hand_slot.global_position.y -= 0.5


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
			else:
				item.release_claim()
		
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
	
	if hot_bar != null:
		var success = hot_bar.try_drop(dropped_item)
		if success:
			_show_item(dropped_item)
	
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

func try_split_item(item: FactoryItem = null) -> bool:
	# if null, then its trying to split the held item
	if item == null:
		item = inventory.hand_slot
	
	var quantity = item.stack.quantity
	# cannot split if: size = 1
	if quantity == 1:
		print ("false")
		return false
	
	# TO DO: fix this based on expected behavior
	var half: int = quantity / 2
	var new_stack = item.stack.split(half)
	# TO DO: fix this as well if we want different behavior
	var spawn_position = item.transform.origin + Vector3(0.5, 0, 0)
	var factory_item = FactoryItemFactory.spawn_factory_item(
		item.stack.item_definition, 
		spawn_position, 
		item.factory_manager,
		new_stack)
		
	if factory_item == null:
		return false

	return true
	
func _hide_item(item: FactoryItem) -> void:
	if item != null:
		item.sprite.visible = false

func _show_item(item: FactoryItem) -> void:
	if item != null:
		item.sprite.visible = true

func _bind_hot_bar() -> void:
	if hot_bar != null:
		hot_bar.selected_item_changed.connect(_on_hot_bar_selection)

func _on_hot_bar_selection(item: FactoryItem):
	if inventory.hand_slot != null and inventory.hand_slot != item:
		_hide_item(inventory.hand_slot)
	set_held_item(item)
