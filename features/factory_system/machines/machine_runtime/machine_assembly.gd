@tool
class_name MachineAssembly
extends Node3D

@export var block: Block
@export var machine: Machine
@export var ui_panels: Array[PackedScene] = []
@export var blueprint: Machine
@export var progress_bar: Node3D

@export var toggle_blueprint: bool

const BLUEPRINT_UI_PANEL := preload(
	"res://features/factory_system/machines/ui/blueprint_panel.tscn"
)

var _factory_manager: FactoryManager


func is_blueprint_active() -> bool:
	return toggle_blueprint and blueprint != null and not blueprint.disabled


## Machine the machine UI should bind to: the blueprint while under construction.
func get_ui_machine() -> Machine:
	return blueprint if is_blueprint_active() else machine


## Panels shown in the machine UI. A blueprint only shows the blueprint panel.
func get_ui_panels() -> Array[PackedScene]:
	if is_blueprint_active():
		return [BLUEPRINT_UI_PANEL]
	return ui_panels

func configure(
	factory_manager: FactoryManager,
	faith_manager: FaithManager,
	job_board: JobBoard,
	reservation_manager: ReservationManager,
	mobs_root: Node,
	_grid: Grid
) -> void:
	assert(block != null, "MachineAssembly requires a Block")
	assert(machine != null, "MachineAssembly requires a Machine")
	_factory_manager = factory_manager
	
	machine.configure(faith_manager, mobs_root)
	if machine.job_provider != null:
		machine.job_provider.configure(
			factory_manager,
			job_board,
			reservation_manager,
			machine,
		)

	if toggle_blueprint:
		assert(blueprint != null, "MachineAssembly requires a Blueprint")
		assert(
			blueprint is BlueprintMachine,
			"MachineAssembly blueprint must be a BlueprintMachine",
		)
		(blueprint as BlueprintMachine).configure_construction(
			machine.definition,
		)
		block.set_appearence(Block.Appearance.TRANSLUCENT_BLUE)
		block.set_blueprint_layer(true)
		machine.disable()
		blueprint.enable()

		blueprint.configure(faith_manager, mobs_root)
		if not blueprint.blueprint_constructed.is_connected(blueprint_constructed):
			blueprint.blueprint_constructed.connect(blueprint_constructed)
		if blueprint.job_provider != null:
			blueprint.job_provider.configure(
				factory_manager,
				job_board,
				reservation_manager,
				blueprint,
			)
		if progress_bar != null:
			progress_bar.machine = blueprint

func _ready() -> void:
	if not toggle_blueprint:
		blueprint_constructed()


func blueprint_constructed() -> void:
	if (
		_factory_manager != null
		and blueprint != null
		and _factory_manager.is_machine_registered(blueprint)
	):
		_factory_manager.unregister_machine(blueprint)
	if progress_bar != null:
		progress_bar.machine = machine
	if blueprint != null:
		blueprint.disable()
	machine.enable()
	block.set_blueprint_layer(false)
	block.set_appearence(Block.Appearance.NORMAL)

func register_machines(
	factory_manager: FactoryManager,
	center_cell: Vector3i,
) -> bool:
	machine.center_position = center_cell
	if not factory_manager.register_machine(machine):
		return false

	if not toggle_blueprint:
		return true

	assert(blueprint != null, "MachineAssembly requires a Blueprint")
	blueprint.center_position = center_cell
	if factory_manager.register_machine(blueprint):
		return true

	factory_manager.unregister_machine(machine)
	return false




## Register an assembly already present in the scene after Grid._ready().
## Placement previews are registered by MachinePlacementController on confirmation.
func register_preplaced(grid: Grid, factory_manager: FactoryManager) -> bool:
	rebuild_block_data(grid)

	if not grid.register_block(block):
		push_warning("Invalid preplaced machine: block cannot be registered")
		queue_free()
		return false

	if not register_machines(factory_manager, block.block_data.root_cell):
		grid.unregister_block(block)
		push_warning("Invalid preplaced machine: machines cannot be registered")
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
