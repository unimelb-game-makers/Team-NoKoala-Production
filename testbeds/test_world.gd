@tool 
class_name TestWorld
extends Node3D


@export_group("Required Dependency")
@export var grid: Grid
@export var clock: FixedClock
@export var factory: FactoryManager


@export_group("Optional Dependency")
@export var placement: MachinePlacementController
@export var faith: FaithManager
@export var jobs: JobBoard
@export var reservations: ReservationManager
@export var pathfinder: Pathfinder
@export var item_spawner: FactoryItemSpawnController
@export var spring_arm: CameraController
@export var player: Player
@export var mobs_root: Node
@export var machines_root: Node
@export var faith_bar: FaithProgressBar
@export var hotbar: Hotbar
@export var resource_area_manager: ResourceAreaManager

@export_tool_button("Configure Editor Dependency", "Callable")
var configure_editor = configure_editor_dependencies

func _enter_tree() -> void:
	assert(grid != null, "TestWorld requires a Grid")
	assert(clock != null, "TestWorld requires a FixedClock")
	assert(factory != null, "TestWorld requires a FactoryManager")
	configure_dependencies()

func _ready() -> void:
	if machines_root == null:
		return
	for child in machines_root.get_children():
		if child is MachineAssembly:
			child.register_preplaced(grid, factory)


func configure_dependencies() -> void:
	factory.configure(grid, clock, faith)

	if pathfinder != null:
		pathfinder.configure(factory)

	if placement != null:
		assert(faith != null, "Placement requires a FaithManager")
		assert(jobs != null, "Placement requires a JobBoard")
		assert(reservations != null, "Placement requires a ReservationManager")
		assert(spring_arm != null, "Placement requires a SpringArm")
		placement.configure(grid, factory, faith, jobs, reservations, spring_arm)

	if item_spawner != null:
		assert(spring_arm != null, "ItemSpawner requires a SpringArm")
		item_spawner.configure(spring_arm, grid, factory)

	if player != null:
		assert(placement != null, "Player requires a MachinePlacementController")
		assert(jobs != null, "Player requires a JobBoard")
		assert(spring_arm != null, "Player requires a SpringArm")
		player.configure(spring_arm, placement, jobs, grid, factory, hotbar)

	if spring_arm != null:
		assert(player != null, "SpringArm requires a Player")
		spring_arm.configure(player)

	if mobs_root != null:
		assert(pathfinder != null, "Mobs require a Pathfinder")
		assert(jobs != null, "Mobs require a JobBoard")
		assert(reservations != null, "Mobs require a ReservationManager")
		assert(faith != null, "Mobs require a FaithManage")
		for child in mobs_root.get_children():
			if child is Npc:
				child.configure(
					clock,
					jobs,
					reservations,
					grid,
					pathfinder,
					faith,
				)

	if machines_root != null:
		assert(factory != null, "Machines requires a FactoryManager")
		assert(faith != null, "Machines requires a FaithManager")
		assert(jobs != null, "Machines require a JobBoard")
		assert(reservations != null, "Machines require a ReservationManager")
		assert(grid != null, "Machines require a Grid")

		for child in machines_root.get_children():
			if child is MachineAssembly:
				child.configure(factory,faith,jobs,reservations, grid)
	print(factory._machines.size())
	
	if faith != null:
		if faith_bar != null:
			faith_bar.bind(faith)

	if resource_area_manager != null:
			assert(grid != null)
			assert(factory != null)
			resource_area_manager.configure(grid, machines_root)


func configure_editor_dependencies() -> void:
	if resource_area_manager != null:
			assert(grid != null)
			assert(factory != null)
			resource_area_manager.configure(grid, machines_root)
