class_name MachineAssembly
extends Node3D

@export var block: Block
@export var machine: Machine
@export var ui_panels: Array[PackedScene] = []


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
			machine,
		)
