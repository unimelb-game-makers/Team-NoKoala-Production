class_name WorldServices
extends Node

@export var fixed_clock: FixedClock
@export var factory_manager: FactoryManager
@export var recipe_unlocks: RecipeUnlocks
@export var machine_factory: MachineFactory
@export var item_spawner: ItemSpawner
@export var spirit_spawner: SpiritSpawner
@export var faith_manager: FaithManager
@export var job_board: JobBoard
@export var reservation_manager: ReservationManager
@export var machine_placement_controller: MachinePlacementController
@export var item_spawn_controller: FactoryItemSpawnController
@export var dialogue_coordinator: DialogueCoordinator


func configure(
	grid: Grid,
	spring_arm: CameraController,
	machines_root: Node,
	mobs_root: Node,
	items_root: Node,
) -> void:
	factory_manager.configure(grid, fixed_clock, faith_manager, item_spawner, recipe_unlocks)
	item_spawner.configure(items_root, factory_manager)
	machine_placement_controller.configure(
		machine_factory,
		grid,
		factory_manager,
		spirit_spawner,
		faith_manager,
		job_board,
		reservation_manager,
		machines_root,
		mobs_root,
		spring_arm,
	)
	item_spawn_controller.configure(spring_arm, grid, item_spawner)
	spirit_spawner.configure(mobs_root, fixed_clock, job_board, reservation_manager, grid, faith_manager)
