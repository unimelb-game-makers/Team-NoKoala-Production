class_name GameWorld
extends Node3D

@export var world_services: WorldServices
@export var grid: Grid
@export var player: Player
@export var spring_arm: CameraController
@export var mobs_root: Node
@export var machines_root: Node
@export var buildings_root: Node
@export var items_root: Node
@export var world_ui: WorldUI

var context: WorldContext
var _composed := false


func _enter_tree() -> void:
	if _composed == false:
		validate_dependencies()
		compose_world_context()
		configure_dependencies()
	add_to_group("world")


func _ready() -> void:
	for child in machines_root.get_children():
		if child is MachineAssembly:
			child.register_preplaced(grid, world_services.factory_manager)
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
	context.clock = world_services.fixed_clock
	context.factory = world_services.factory_manager
	context.faith = world_services.faith_manager
	context.jobs = world_services.job_board
	context.reservations = world_services.reservation_manager
	context.player = player
	context.dialogue_coordinator = world_services.dialogue_coordinator

	_composed = true
	return context


func configure_dependencies() -> void:
	world_services.configure(grid, spring_arm, machines_root, mobs_root, items_root)
	world_ui.configure(
		world_services.faith_manager,
		world_services.machine_placement_controller,
		world_services.feature_gate,
		world_services.tutorial_director,
	)
	grid.configure(world_services.factory_manager)
	player.configure(
		spring_arm,
		world_services.machine_placement_controller,
		world_services.job_board,
		grid,
		world_services.factory_manager,
		world_ui.hotbar,
		world_ui.machine_ui,
		world_services.feature_gate,
	)
	spring_arm.configure(player, world_services.feature_gate)
	world_services.tutorial_director.configure(
		world_services.feature_gate,
		world_services.factory_manager,
		world_services.dialogue_coordinator,
		player,
		spring_arm,
		world_services.machine_placement_controller,
	)
	for child in mobs_root.get_children():
		if child is Npc:
			child.configure(
				world_services.fixed_clock,
				world_services.job_board,
				world_services.reservation_manager,
				grid,
				world_services.faith_manager
			)
	for child in machines_root.get_children():
		if child is MachineAssembly:
			child.configure(
				world_services.factory_manager,
				world_services.faith_manager,
				world_services.job_board,
				world_services.reservation_manager,
				world_services.spirit_spawner,
				mobs_root,
				grid
			)


func shutdown() -> void:
	pass


func validate_dependencies() -> void:
	assert(world_services != null, "GameWorld requires a WorldServices")
	assert(grid != null, "GameWorld requires a Grid")
	assert(player != null, "GameWorld requires a Player")
	assert(spring_arm != null, "GameWorld requires a SpringArm")
	assert(machines_root != null, "GameWorld requires a machines root")
	assert(buildings_root != null, "GameWorld requires a buildings root")
	assert(items_root != null, "GameWorld requires an items root")
	assert(world_ui != null, "GameWorld requires a WorldUI")
	assert(mobs_root != null, "GameWorld requires a mobs root")
