class_name ControlVisibleCondition
extends TutorialCondition

## Group of the Control to watch. Add the Control to this group in its scene.
@export var control_group: StringName
## Satisfied when the Control is visible in the tree (true) or not (false).
@export var visible := true

var _control: Control


func start(ctx: TutorialContext) -> void:
	_control = ctx.tree.get_first_node_in_group(control_group) as Control
	if _control == null:
		push_error("ControlVisibleCondition: no Control in group '%s'" % control_group)
		return
	_control.visibility_changed.connect(_check)
	_check()


func stop() -> void:
	if is_instance_valid(_control) and _control.visibility_changed.is_connected(_check):
		_control.visibility_changed.disconnect(_check)
	_control = null


func _check() -> void:
	if _control.is_visible_in_tree() == visible:
		satisfied.emit()
