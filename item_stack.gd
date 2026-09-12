class_name ItemStack
extends Resource

# TO DO: if item stack could ever represent a non-factory item, change this
@export var item_id : FactoryItemDefinition
@export var stack_size: int = 3
@export var quantity: int = 1

static func create(definition: FactoryItemDefinition, amount: int = 1) -> ItemStack:
	var new_stack := ItemStack.new()
	new_stack.item_id = definition
	new_stack.quantity = amount
	return new_stack

func can_merge_with(other: ItemStack) -> bool:
	# check if other exists and id compatability
	return other != null and other.item_id == item_id and not is_full()
	
func space_remaining() -> int:
	return stack_size - quantity

func is_full() -> bool:
	return quantity >= stack_size

func is_empty() -> bool:
	return quantity <= 0

func merge_from(other: ItemStack) -> int:
	if not can_merge_with(other):
		return other.quantity
	# move as much from other into this stack, return the left over
	var combined_quantity = other.quantity + quantity
	if combined_quantity <= stack_size:
		quantity = combined_quantity
		other.quantity = 0
		return 0
	else:
		var leftover = combined_quantity - stack_size
		quantity = stack_size
		other.quantity = leftover
		return leftover

func split(amount: int) -> ItemStack:
	if amount <= 0 or amount >= quantity:
		return null # TO DO: maybe assert an error here
	# split the amount off into a new stack, reduce this stack, check amount validity
	var new_stack = ItemStack.new()
	new_stack.item_id = item_id
	new_stack.quantity = amount
	new_stack.stack_size = stack_size
	quantity -= amount
	return new_stack
