class_name ReachAreaCondition
extends TutorialCondition

## Satisfied when the player enters the Area3D in this group.
@export var area_group: StringName

var _ctx: TutorialContext
var _area: Area3D


func start(ctx: TutorialContext) -> void:
	_ctx = ctx
	_area = ctx.tree.get_first_node_in_group(area_group) as Area3D
	if _area == null:
		push_error("ReachAreaCondition: no Area3D in group '%s'" % area_group)
		return
	if _area.overlaps_body(ctx.player):
		satisfied.emit()
		return
	_area.body_entered.connect(_on_body_entered)


func stop() -> void:
	if is_instance_valid(_area) and _area.body_entered.is_connected(_on_body_entered):
		_area.body_entered.disconnect(_on_body_entered)
	_area = null
	_ctx = null


func _on_body_entered(body: Node3D) -> void:
	if body == _ctx.player:
		satisfied.emit()
