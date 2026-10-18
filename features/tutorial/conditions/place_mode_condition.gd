class_name PlaceModeCondition
extends TutorialCondition

## Satisfied when machine placement mode is on (true) or off (false).
@export var enabled := true

var _placement: MachinePlacementController


func start(ctx: TutorialContext) -> void:
	_placement = ctx.placement
	_placement.place_mode_changed.connect(_on_place_mode_changed)
	if _placement.place_mode == enabled:
		satisfied.emit()


func stop() -> void:
	if _placement != null and _placement.place_mode_changed.is_connected(_on_place_mode_changed):
		_placement.place_mode_changed.disconnect(_on_place_mode_changed)
	_placement = null


func _on_place_mode_changed(is_enabled: bool) -> void:
	if is_enabled == enabled:
		satisfied.emit()
