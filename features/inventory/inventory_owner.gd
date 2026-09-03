class_name InventoryOwner
extends Node

@export var pickup_distance: float = 4.0

var actor: Node3D
var inventory: Inventory = Inventory.new()


func _ready() -> void:
	actor = get_parent()


func _process(_delta: float) -> void:
	if inventory.hand_slot != null:
		inventory.hand_slot.global_position = actor.global_position


func set_held_item(item: FactoryItem) -> void:
	inventory.hand_slot = item


func try_pick_up_item(item: FactoryItem) -> bool:
	if item == null:
		return false
	if actor.global_position.distance_to(item.global_position) > pickup_distance:
		return false
	if not item.try_claim(actor):
		return false

	set_held_item(item)
	return true


func try_drop_held_item() -> bool:
	if inventory.hand_slot == null:
		return false

	var drop_position = actor.global_position
	drop_position.y = 0
	inventory.hand_slot.drop_at(drop_position)
	inventory.hand_slot.global_position = drop_position
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
