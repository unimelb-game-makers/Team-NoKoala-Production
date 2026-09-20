class_name MachineAssembly
extends Node3D

@export var block: Block
@export var machine: Machine
@export var block_registration: BlockGridRegistration


func configure(
	factory_manager: FactoryManager,
	faith_manager: FaithManager,
	job_board: JobBoard,
	reservation_manager: ReservationManager,
	_grid: Grid
) -> void:
	assert(block != null, "MachineAssembly requires a Block")
	assert(machine != null, "MachineAssembly requires a Machine")
	machine.configure(faith_manager)
	if machine.job_provider != null:
		machine.job_provider.configure(
			factory_manager,
			job_board,
			reservation_manager,
		)


## Register an assembly already present in the scene after Grid._ready().
## Placement previews are registered by MachinePlacementController on confirmation.
func register_preplaced(grid: Grid, factory_manager: FactoryManager) -> bool:
	if block.block_data == null or not grid.register_block(block):
		push_warning("Invalid preplaced machine: block cannot be registered")
		queue_free()
		return false

	machine.center_position = block.block_data.root_cell
	if not factory_manager.register_machine(machine):
		grid.unregister_block(block)
		push_warning("Invalid preplaced machine: machine cannot be registered")
		queue_free()
		return false

	return true
