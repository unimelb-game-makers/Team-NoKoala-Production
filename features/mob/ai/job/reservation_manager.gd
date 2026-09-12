class_name ReservationManager

# A "target" is anything a job needs sole access to while it runs.
# An "owner" is the `JobConsumer` holding the claim.
static var _owner_of: Dictionary = {}
static var _targets_of: Dictionary = {}


## Reserves target for owner. Succeeds if the target is free or
## already held by the same owner; fails if another owner holds it.
static func try_reserve(owner: Object, target: Variant) -> bool:
	if owner == null or target == null:
		return false

	_prune()

	var holder: Variant = _owner_of.get(target)
	if holder != null and holder != owner:
		return false

	_owner_of[target] = owner
	var targets: Array = _targets_of.get(owner, [])
	if not targets.has(target):
		targets.append(target)
	_targets_of[owner] = targets
	return true


## Reserves every target for owner, all-or-nothing. On the first
## failure any partial reservations from this call are rolled back.
static func try_reserve_all(owner: Object, targets: Array) -> bool:
	var acquired: Array = []
	for target in targets:
		if try_reserve(owner, target):
			acquired.append(target)
		else:
			for reserved in acquired:
				release(owner, reserved)
			return false
	return true


## Releases a single target if it is held by owner.
static func release(owner: Object, target: Variant) -> void:
	if _owner_of.get(target) == owner:
		_owner_of.erase(target)

	var targets: Array = _targets_of.get(owner, [])
	targets.erase(target)
	if targets.is_empty():
		_targets_of.erase(owner)
	else:
		_targets_of[owner] = targets


## Releases every target held by owner. Call this when a job ends or
## the owner is removed.
static func release_all(owner: Object) -> void:
	for target in _targets_of.get(owner, []).duplicate():
		if _owner_of.get(target) == owner:
			_owner_of.erase(target)
	_targets_of.erase(owner)


## Whether target is held by anyone other than `ignoring`.
## A claim whose owner has been freed is dropped and reported as free.
static func is_reserved(target: Variant, ignoring: Object = null) -> bool:
	var holder: Variant = _owner_of.get(target)
	if holder == null:
		return false
	if not is_instance_valid(holder):
		_release_target(target)
		return false
	return holder != ignoring


## Wipes the whole store. Intended for tests and scene reloads.
static func clear() -> void:
	_owner_of.clear()
	_targets_of.clear()


static func _release_target(target: Variant) -> void:
	var holder: Variant = _owner_of.get(target)
	if holder == null:
		return
	_owner_of.erase(target)
	if _targets_of.has(holder):
		_targets_of[holder].erase(target)
		if _targets_of[holder].is_empty():
			_targets_of.erase(holder)


static func _prune() -> void:
	for owner in _targets_of.keys():
		if not is_instance_valid(owner):
			for target in _targets_of[owner]:
				_owner_of.erase(target)
			_targets_of.erase(owner)

	for target in _owner_of.keys():
		if target is Object and not is_instance_valid(target):
			_release_target(target)
