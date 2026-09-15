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
@export var placement: MachinePlacementController
@export var item_spawner: FactoryItemSpawnController
@export var mobs_root: Node

var context: WorldContext
var _composed := false
var _shut_down := false


func _enter_tree() -> void:
	assert(_composed, "GameWorld must be composed by App before entering the tree")

## Builds this world's service scope before any child enters the tree.
func compose() -> void:
	if _composed:
		return

	_validate_composition()
	_initialize_services()
	_inject_dependencies()
	_composed = true

func _initialize_services() -> void:
	context = WorldContext.new()
	context.grid = grid
	context.clock = clock
	context.factory = factory
	context.faith = faith
	context.jobs = jobs
	context.reservations = reservations
	context.pathfinder = pathfinder
	context.placement = placement
	context.player = player

func _inject_dependencies() -> void:
	factory.configure(grid, clock)
	pathfinder.configure(factory)
	placement.configure(context)
	item_spawner.configure(grid, factory)
	player.configure(context)
	for child in mobs_root.get_children():
		assert(
			child.has_method(&"configure_world"),
			"Every direct child of GameWorld.mobs_root must accept WorldContext",
		)
		child.call(&"configure_world", context)


func shutdown() -> void:
	if _shut_down:
		return
	_shut_down = true

	if placement != null:
		placement.cancel_placement()
	jobs.clear()
	reservations.clear()
	faith.clear()


func _validate_composition() -> void:
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
