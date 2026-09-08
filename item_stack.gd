class_name ItemStack
extends Resource

@export var item_id: StringName = &""
@export var stack_size: int = 1
@export var quantity: int = 1

func can_merge_with(other: ItemStack) -> bool:
	# check if other exists and id compatability
	return true
	
func space_remaining() -> int:
	return stack_size - quantity

func is_full() -> bool:
	return quantity == stack_size

func merge_from(other: ItemStack) -> int:
	# move as much from other into this stack, return the left over
	return 1

func split(amount: int) -> ItemStack:
	# split the amount off into a new stack, reduce this stack, check amount validity
	return self
