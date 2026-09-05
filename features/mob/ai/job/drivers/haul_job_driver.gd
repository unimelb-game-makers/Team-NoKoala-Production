class_name HaulJobDriver
extends JobDriver

enum State {
	MOVE_TO_ITEM,
	PICK_UP_ITEM,
	MOVE_TO_DESTINATION,
	PLACE_ITEM,
}

var inventory_owner: InventoryOwner
var movement: Movement
var grid: Grid

var state := State.MOVE_TO_ITEM
var elapsed := 0.0

## The `State` we last handed to `movement.start_moving_to`, so each leg issues
## its move exactly once (re-issuing would also mask a stale FAILED status left
## on the shared Movement node by a previous job).
var _move_issued_for := -1

const MAX_DURATION := 60.0


func start() -> Status:
	inventory_owner = NodeUtils.get_child_by_type(consumer.actor, InventoryOwner)
	movement = NodeUtils.get_child_by_type(consumer.actor, Movement)
	grid = consumer.get_tree().get_first_node_in_group("grid")
	if inventory_owner == null:
		return Status.FAILURE
	else:
		return Status.SUCCESS


func tick(delta: float) -> Status:
	elapsed += delta
	if elapsed > MAX_DURATION:
		return _abort()

	match state:
		State.MOVE_TO_ITEM:
			if not is_instance_valid(job.item):
				return _abort()

			# Someone else (the player, a machine) grabbed it before we arrived.
			if job.item.is_claimed():
				return _abort()

			return _drive_to(ground_target(job.item.global_position), State.PICK_UP_ITEM)

		State.PICK_UP_ITEM:
			if not pickup_item():
				return _abort()

			state = State.MOVE_TO_DESTINATION

		State.MOVE_TO_DESTINATION:
			return _drive_to(ground_target(grid.cell_to_world(job.storage)), State.PLACE_ITEM)

		State.PLACE_ITEM:
			place_item()
			return Status.SUCCESS

	return Status.RUNNING


## Steers the mob toward `target`. Advances to `next_state` on arrival, or
## aborts the job when the pathfinder reports the target unreachable (e.g. a
## machine was placed across the only route).
func _drive_to(target: Vector3, next_state: State) -> Status:
	if movement.within_stop_distance(target):
		state = next_state
		return Status.RUNNING

	if _move_issued_for != state:
		movement.start_moving_to(target)
		_move_issued_for = state
	elif movement.status == Movement.Status.FAILED:
		return _abort()

	return Status.RUNNING


func ground_target(target: Vector3) -> Vector3:
	return Vector3(target.x, consumer.actor.global_position.y, target.z)


func pickup_item() -> bool:
	return inventory_owner.try_pick_up_item(job.item)


func place_item() -> void:
	inventory_owner.try_place_held_item(grid.cell_to_world(job.storage))


func _abort() -> Status:
	inventory_owner.try_drop_held_item()
	return Status.FAILURE
