class_name ItemsHeldCondition
extends TutorialCondition

## Satisfied once the player's inventory holds at least [member count] items of
## [member item_definition], summed over every slot.
@export var item_definition: FactoryItemDefinition
@export var count := 1

var _ctx: TutorialContext
var _inventory: Inventory
var _held := -1


func has_progress() -> bool:
	return true


func start(ctx: TutorialContext) -> void:
	_ctx = ctx
	_held = -1
	var owner := NodeUtils.get_child_by_type(ctx.player, InventoryOwner) as InventoryOwner
	if owner == null or item_definition == null:
		push_error("ItemsHeldCondition: needs a player InventoryOwner and an item definition")
		return
	_inventory = owner.inventory
	# stacks merge by changing their quantity without a slot_changed, so poll
	ctx.ticked.connect(_on_tick)
	_on_tick(0.0)


func stop() -> void:
	if _ctx != null and _ctx.ticked.is_connected(_on_tick):
		_ctx.ticked.disconnect(_on_tick)
	_ctx = null
	_inventory = null


func _on_tick(_delta: float) -> void:
	var held := _count_held()
	if held == _held:
		return
	_held = held
	progress_changed.emit(minf(float(held) / maxf(count, 1), 1.0))
	if held >= count:
		stop()
		satisfied.emit()


func _count_held() -> int:
	var total := 0
	for item in _inventory.slots:
		if item != null and item.stack != null and item.stack.item_id == item_definition.item_key:
			total += item.stack.quantity
	return total
