class_name TestWorld
extends Node3D

@export_group("Required Dependency")
@export var world_services: WorldServices
@export var grid: Grid
@export var spring_arm: CameraController
@export var player: Player

@export_group("Optional Dependency")
@export var world_ui: WorldUI
@export var items_root: Node
@export var mobs_root: Node
@export var machines_root: Node


func _enter_tree() -> void:
	assert(world_services != null, "TestWorld requires a WorldServices")

	configure_dependencies()


func _ready() -> void:
	if machines_root == null:
		return
	for child in machines_root.get_children():
		if child is MachineAssembly:
			child.register_preplaced(grid, world_services.factory_manager)


func configure_dependencies() -> void:
	world_services.configure(grid, spring_arm, machines_root, mobs_root, items_root)

	grid.configure(world_services.factory_manager)

	if player != null:
		assert(spring_arm != null, "Player requires a SpringArm")
		player.configure(
			spring_arm,
			world_services.machine_placement_controller,
			world_services.job_board,
			grid,
			world_services.factory_manager,
			world_ui.hotbar if world_ui != null else null,
			world_ui.machine_ui if world_ui != null else null
		)

	if spring_arm != null:
		assert(player != null, "SpringArm requires a Player")
		spring_arm.configure(player)

	if mobs_root != null:
		for child in mobs_root.get_children():
			if child is Npc:
				child.configure(
					world_services.fixed_clock,
					world_services.job_board,
					world_services.reservation_manager,
					grid,
					world_services.faith_manager,
				)

	if machines_root != null:
		assert(grid != null, "Machines require a Grid")

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
	
	if world_ui != null:
		world_ui.configure(world_services.faith_manager, world_services.machine_placement_controller)
	
	print(world_services.factory_manager._machines.size())
