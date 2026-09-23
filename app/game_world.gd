@tool
class_name GameWorld
extends Node3D

@export var grid: Grid
@export var clock: FixedClock
@export var factory: FactoryManager
@export var faith: FaithManager
@export var jobs: JobBoard
@export var reservations: ReservationManager
@export var pathfinder: Pathfinder
@export var player: Player
@export var spring_arm: CameraController
@export var placement: MachinePlacementController
@export var item_spawner: FactoryItemSpawnController
@export var mobs_root: Node
@export var machines_root: Node
@export var buildings_root: Node
@export var resource_area_manager: ResourceAreaManager
@export_tool_button("Configure Editor Dependency", "Callable")
var configure_editor = configure_editor_dependencies

var context: WorldContext
var _composed := false



func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	if _composed == false:
		compose_world_context()
		configure_dependencies()

func _ready() -> void:
	if Engine.is_editor_hint() or machines_root == null:
		return
	for child in machines_root.get_children():
		if child is MachineAssembly:
			child.register_preplaced(grid, factory)
	for block in buildings_root.get_children():
		if block is Block:
			if block.block_data != null:
				grid.register_block(block)

func configure_world() -> WorldContext:
	if _composed:
		return context

	validate_dependencies()
	configure_dependencies()
	context = compose_world_context()
	_composed = true
	return context

# world context is what pass to other components like ui
func compose_world_context() -> WorldContext:
	if _composed:
		return null

	context = WorldContext.new()
	context.grid = grid
	context.clock = clock
	context.factory = factory
	context.faith = faith
	context.jobs = jobs
	context.reservations = reservations
	context.player = player

	_composed = true
	return context

func configure_dependencies() -> void:
	factory.configure(grid, clock, faith)
	pathfinder.configure(factory)
	placement.configure(grid, factory, faith, jobs, reservations, spring_arm)
	item_spawner.configure(spring_arm, grid, factory)
	player.configure(spring_arm, placement, jobs, grid, factory)
	spring_arm.configure(player)
	for child in mobs_root.get_children():
		if child is Npc:
			child.configure(clock, jobs, reservations, grid, pathfinder, faith)
	for child in machines_root.get_children():
		if child is MachineAssembly:
			child.configure(factory,faith,jobs,reservations,grid)

func configure_editor_dependencies() -> void:
	resource_area_manager.configure(grid,machines_root)


func shutdown() -> void:
	pass


func validate_dependencies() -> void:
	assert(grid != null, "GameWorld requires a Grid")
	assert(clock != null, "GameWorld requires a FixedClock")
	assert(factory != null, "GameWorld requires a FactoryManager")
	assert(faith != null, "GameWorld requires a FaithManager")
	assert(jobs != null, "GameWorld requires a JobBoard")
	assert(reservations != null, "GameWorld requires a ReservationManager")
	assert(pathfinder != null, "GameWorld requires a Pathfinder")
	assert(player != null, "GameWorld requires a Player")
	assert(placement != null, "GameWorld requires a MachinePlacementController")
	assert(item_spawner != null, "GameWorld requires a FactoryItemSpawnController")
	assert(mobs_root != null, "GameWorld requires a mobs root")
