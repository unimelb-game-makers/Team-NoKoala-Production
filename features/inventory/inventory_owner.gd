class_name InventoryOwner
extends Node

@export var pickup_distance: float = 4.0
@export var slot_count: int = 1
@export var hotbar: Hotbar = null
@export var hold_item_offset: Vector3 = Vector3(0, -0.5, 0)

var actor: Node3D
var inventory: Inventory


func configure(p_hotbar: Hotbar) -> void:
	hotbar = p_hotbar


func _ready() -> void:
	actor = get_parent()
	inventory = Inventory.new(slot_count)
	inventory.selected_index_changed.connect(_on_selected_index_changed)
	if hotbar != null:
		hotbar.bind_inventory(inventory)


func _process(_delta: float) -> void:
	if inventory.hand_slot != null:
		inventory.hand_slot.global_position = actor.to_global(hold_item_offset)


func set_held_item(item: FactoryItem) -> void:
	if item == null:
		_hide_item(inventory.hand_slot)
		inventory.hand_slot = null
		return
	
	inventory.hand_slot = item
	_show_item(item)


func try_pick_up_item(item: FactoryItem) -> bool:
	if item == null:
		return false
	if actor.global_position.distance_to(item.global_position) > pickup_distance:
		return false
	if not item.try_claim(actor):
		return false

	var index := inventory.try_add(item)
	if index == -1:
		item.release_claim()
		return false # every slot is holding something incompatible/full

	if item.stack.is_empty():
		item.queue_free() # fully merged into an existing stack
	elif inventory.get_slot(index) != item:
		item.release_claim() # partially merged, the rest stays on the ground
	elif index == inventory.selected_index:
		_show_item(item)
	else:
		_hide_item(item)
	return true

func try_drop_held_item() -> bool:
	if inventory.hand_slot == null:
		return false
	
	var dropped_item = inventory.hand_slot
	var drop_position = actor.global_position
	drop_position.y = 0

	if not dropped_item.try_drop(drop_position):
		return false

	_show_item(dropped_item)
	inventory.hand_slot = null
	return true



func try_place_held_item(target_position: Vector3) -> bool:
	if inventory.hand_slot == null:
		return false
	if actor.global_position.distance_to(target_position) > pickup_distance:
		return false

	var placed_item := inventory.hand_slot
	placed_item.drop_at(target_position)
	placed_item.global_position = target_position
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

func _on_selected_index_changed(previous: int, current: int) -> void:
	_hide_item(inventory.get_slot(previous))
	_show_item(inventory.get_slot(current))
