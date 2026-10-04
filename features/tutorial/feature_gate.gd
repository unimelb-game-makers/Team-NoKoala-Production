class_name FeatureGate
extends Node

## Emitted whenever the set of allowed features changes.
signal changed

var _restricted := false
var _allowed: Dictionary[GameFeature.Id, bool] = {}


## Null-safe check for features that were not given a gate (tests, standalone scenes).
static func check(gate: FeatureGate, feature: GameFeature.Id) -> bool:
	return gate == null or gate.allows(feature)


func allows(feature: GameFeature.Id) -> bool:
	return not _restricted or _allowed.has(feature)


func is_restricted() -> bool:
	return _restricted


## Allows only the given features; everything else is blocked.
func restrict_to(features: Array[GameFeature.Id]) -> void:
	_restricted = true
	_allowed.clear()
	for feature in features:
		_allowed[feature] = true
	changed.emit()


## Allows every feature again.
func lift() -> void:
	if not _restricted:
		return
	_restricted = false
	_allowed.clear()
	changed.emit()
