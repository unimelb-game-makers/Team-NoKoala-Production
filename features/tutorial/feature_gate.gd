class_name FeatureGate
extends Node

## Emitted whenever the set of allowed features changes.
signal changed

var _restricted := false
var _allowed: Dictionary[GameFeature.Id, bool] = {}
## Machines that may be selected for building; empty allows every machine.
var _allowed_machines: Array[MachineDefinition] = []


## Null-safe check for features that were not given a gate (tests, standalone scenes).
static func check(gate: FeatureGate, feature: GameFeature.Id) -> bool:
	return gate == null or gate.allows(feature)


## Null-safe check for whether a machine may be selected for building.
static func check_machine(gate: FeatureGate, definition: MachineDefinition) -> bool:
	return gate == null or gate.allows_machine(definition)


func allows(feature: GameFeature.Id) -> bool:
	return not _restricted or _allowed.has(feature)


func allows_machine(definition: MachineDefinition) -> bool:
	return not _restricted or _allowed_machines.is_empty() or _allowed_machines.has(definition)


func is_restricted() -> bool:
	return _restricted


## Allows only the given features; everything else is blocked. A non-empty
## [param machines] also limits which machines can be selected for building.
func restrict_to(features: Array[GameFeature.Id], machines: Array[MachineDefinition] = []) -> void:
	_restricted = true
	_allowed.clear()
	for feature in features:
		_allowed[feature] = true
	_allowed_machines = machines.duplicate()
	changed.emit()


## Allows every feature again.
func lift() -> void:
	if not _restricted:
		return
	_restricted = false
	_allowed.clear()
	_allowed_machines.clear()
	changed.emit()
