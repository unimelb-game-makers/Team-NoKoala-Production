class_name MachinePlacedCondition
extends TutorialCondition

## Satisfied once [member count] machines are registered after the step starts. With a
## definition set, only machines of that definition count.
@export var machine_definition: MachineDefinition
@export var count := 1
## Optional. Each counted machine's assembly is added to this group, so later steps can
## find or highlight it. Cleared from every node when the condition starts.
@export var tag_group: StringName

var _ctx: TutorialContext
var _placed := 0


func start(ctx: TutorialContext) -> void:
	_ctx = ctx
	_placed = 0
	if not tag_group.is_empty():
		for node in ctx.tree.get_nodes_in_group(tag_group):
			node.remove_from_group(tag_group)
	ctx.factory.machine_registered.connect(_on_machine_registered)


func stop() -> void:
	if _ctx != null and _ctx.factory.machine_registered.is_connected(_on_machine_registered):
		_ctx.factory.machine_registered.disconnect(_on_machine_registered)
	_ctx = null


func _on_machine_registered(machine: Machine) -> void:
	if not _count(machine):
		return
	if not tag_group.is_empty() and machine.machine_assembly != null:
		machine.machine_assembly.add_to_group(tag_group)
	if _placed >= count:
		satisfied.emit()


## Returns whether the machine was counted.
func _count(machine: Machine) -> bool:
	if machine_definition == null or machine.definition == machine_definition:
		_placed += 1
		return true
	return false
