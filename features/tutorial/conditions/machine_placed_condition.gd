class_name MachinePlacedCondition
extends TutorialCondition

## Satisfied once [member count] machines are registered. With a definition set, only
## machines of that definition count. Machines that already exist count too.
@export var machine_definition: MachineDefinition
@export var count := 1

var _ctx: TutorialContext
var _placed := 0


func start(ctx: TutorialContext) -> void:
	_ctx = ctx
	_placed = 0
	ctx.factory.machine_registered.connect(_on_machine_registered)
	for machine in ctx.factory.get_machines():
		_count(machine)
		if _placed >= count:
			satisfied.emit()
			return


func stop() -> void:
	if _ctx != null and _ctx.factory.machine_registered.is_connected(_on_machine_registered):
		_ctx.factory.machine_registered.disconnect(_on_machine_registered)
	_ctx = null


func _on_machine_registered(machine: Machine) -> void:
	_count(machine)
	if _placed >= count:
		satisfied.emit()


func _count(machine: Machine) -> void:
	if machine_definition == null or machine.definition == machine_definition:
		_placed += 1
