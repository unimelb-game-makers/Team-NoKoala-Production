class_name MachineAssembly
extends Node3D

@export var block: Block
@export var blueprint_block: Block
@export var machine: Machine
@export var blueprint: Machine
@export var progress_bar: Node3D

@export var toggle_blueprint: bool

func configure(
	factory_manager: FactoryManager,
	faith_manager: FaithManager,
	job_board: JobBoard,
	reservation_manager: ReservationManager,
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
	
	if toggle_blueprint: assert(blueprint != null, "MachineAssembly requires a Blueprint")
	blueprint.configure(faith_manager)
	blueprint.blueprint_constructed.connect(blueprint_constructed)
	if blueprint.job_provider != null:
		blueprint.job_provider.configure(
			factory_manager,
			job_board,
			reservation_manager,
		)

func blueprint_constructed() -> void:
	progress_bar.machine = machine
	blueprint.disable()
	machine.enable()
	block.set_appearence(Block.Appearance.NORMAL)
