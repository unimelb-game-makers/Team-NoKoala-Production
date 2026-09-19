@tool
class_name MachineAssembly
extends Node3D

@export var block: Block
@export var blueprint_block: Block
@export var machine: Machine
@export var ui_panels: Array[PackedScene] = []
@export var blueprint: Machine
@export var progress_bar: Node3D

@export var toggle_blueprint: bool

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
			machine,
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




## Register an assembly already present in the scene after Grid._ready().
## Placement previews are registered by MachinePlacementController on confirmation.
func register_preplaced(grid: Grid, factory_manager: FactoryManager) -> bool:
	rebuild_block_data(grid)

	if not grid.register_block(block):
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


func rebuild_block_data(grid: Grid) -> void:
	if block.block_data == null:
		block.block_data = BlockData.new()

	var footprint: Array[Vector3i] = []
	var overlap_cells: Array[Vector3i] = []

	for cell in machine.definition.cells:
		footprint.append(cell.local_cell_offset)
		if cell.can_overlap:
			overlap_cells.append(cell.local_cell_offset)

	block.block_data.footprint = footprint
	block.block_data.overlap_cells = overlap_cells

	var transform_root := block.get_transform_root()
	block.block_data.root_cell = grid.world_to_cell(
		transform_root.global_position,
	)
	block.block_data.block_rotation = grid.world_to_grid_rotation(
		transform_root.global_rotation_degrees.y,
	)
