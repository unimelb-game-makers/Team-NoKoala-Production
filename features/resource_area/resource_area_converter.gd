@tool
extends Node
class_name ResourceAreaConverter

@export var grid: Grid
@export var machine_root: Node

@export_tool_button("Create Machines", "Callable")
var create_machines_button = _create_machines_from_grid

@export_tool_button("Convert Machines to Grid Meshes", "Callable")
var convert_machines_button = _convert_machines_to_grid


const BAMBOO_CULM_SCENE = preload("res://features/resource_area/scenes/bamboo_culm_resourcearea.tscn")
const IRON_ORE_SCENE = preload("res://features/resource_area/scenes/iron_ore_resourcearea.tscn")

var machine_scene_by_mesh_name: Dictionary[StringName, Resource] = {
	&"RA_BAMBOO_CULM": BAMBOO_CULM_SCENE,
	&"RA_IRON_ORE": IRON_ORE_SCENE,
}


## Editor-only: goes through the editor's undo history so the whole batch can be undone.
func _create_machines_from_grid() -> void:
	if not Engine.is_editor_hint():
		return
	if grid == null or machine_root == null or grid.mesh_library == null:
		return

	var scene_root := get_tree().edited_scene_root
	var undo_redo := EditorInterface.get_editor_undo_redo()
	undo_redo.create_action("Create Resource Area Machines", UndoRedo.MERGE_DISABLE, scene_root)

	var resources_created = 0
	for cell in grid.get_used_cells():
		var item := grid.get_cell_item(cell)
		var mesh_name := grid.mesh_library.get_item_name(item)
		var scene := machine_scene_by_mesh_name.get(mesh_name) as PackedScene
		if scene == null:
			continue

		var root := scene.instantiate()
		var assembly := root as MachineAssembly
		if assembly == null or assembly.block == null or assembly.machine == null or assembly.machine.definition == null:
			root.free()
			continue
		var definition := assembly.machine.definition as MachineDefinition
		var grid_rotation := _cell_orientation_to_grid_rotation(grid.get_cell_item_orientation(cell))
		assembly.block.block_data = definition.create_block_data()
		assembly.block.block_data.block_rotation = grid_rotation
		assembly.name = definition.resource_path.get_file().get_basename()
		var world_transform := Transform3D(
			Basis.from_euler(Vector3(0.0, deg_to_rad(grid.grid_to_world_rotation(grid_rotation)), 0.0)),
			grid.cell_to_world(cell),
		)
		assembly.transform = _get_machine_root_global_transform().affine_inverse() * world_transform

		undo_redo.add_do_method(machine_root, "add_child", assembly, true)
		undo_redo.add_do_property(assembly, "owner", scene_root)
		# Keeps the node alive while it is only referenced by the history.
		undo_redo.add_do_reference(assembly)
		undo_redo.add_undo_method(machine_root, "remove_child", assembly)

		# Clear mesh from gridmap cell
		undo_redo.add_do_method(grid, "set_cell_item", cell, -1)
		undo_redo.add_undo_method(grid, "set_cell_item", cell, item, grid.get_cell_item_orientation(cell))
		resources_created += 1

	undo_redo.commit_action()
	print(resources_created, " resource areas created")


## Editor-only: reverse of [method _create_machines_from_grid] for every resource area under [member machine_root].
func _convert_machines_to_grid() -> void:
	if not Engine.is_editor_hint():
		return
	if grid == null or machine_root == null or grid.mesh_library == null:
		return

	var scene_root := get_tree().edited_scene_root
	var undo_redo := EditorInterface.get_editor_undo_redo()
	undo_redo.create_action("Convert Resource Area Machines to Grid Meshes", UndoRedo.MERGE_DISABLE, scene_root)

	var resources_converted = 0
	# Undo re-adds children in this (ascending index) order, so move_child restores each index.
	for node in machine_root.get_children():
		var assembly := node as MachineAssembly
		if assembly == null:
			continue
		var mesh_name := _get_mesh_name_for_scene(assembly.scene_file_path)
		if mesh_name.is_empty():
			continue
		var item := grid.mesh_library.find_item_by_name(mesh_name)
		if item == -1:
			push_warning("Mesh library has no item named %s" % mesh_name)
			continue

		var cell := grid.world_to_cell(assembly.global_position)
		var grid_rotation := grid.world_to_grid_rotation(assembly.global_rotation_degrees.y)
		undo_redo.add_do_method(grid, "set_cell_item", cell, item, _grid_rotation_to_cell_orientation(grid_rotation))
		undo_redo.add_undo_method(grid, "set_cell_item", cell, grid.get_cell_item(cell), grid.get_cell_item_orientation(cell))

		undo_redo.add_do_method(machine_root, "remove_child", assembly)
		undo_redo.add_undo_method(machine_root, "add_child", assembly, true)
		undo_redo.add_undo_method(machine_root, "move_child", assembly, assembly.get_index())
		# Removing the node from the tree clears its owner.
		undo_redo.add_undo_property(assembly, "owner", assembly.owner)
		# Keeps the node alive while it is only referenced by the history.
		undo_redo.add_undo_reference(assembly)
		resources_converted += 1

	undo_redo.commit_action()
	print(resources_converted, " resource areas converted")


## Children of a plain [Node] inherit the transform of its nearest [Node3D] ancestor, so use that.
func _get_machine_root_global_transform() -> Transform3D:
	var node := machine_root
	while node != null:
		var node_3d := node as Node3D
		if node_3d != null:
			return node_3d.global_transform
		node = node.get_parent()
	return Transform3D.IDENTITY


func _get_mesh_name_for_scene(scene_path: String) -> StringName:
	for mesh_name in machine_scene_by_mesh_name:
		if machine_scene_by_mesh_name[mesh_name].resource_path == scene_path:
			return mesh_name
	return &""


## Grid cell orientations can also tilt; only the Y rotation is kept, snapped to 90 degrees.
func _cell_orientation_to_grid_rotation(orientation: int) -> BlockData.Rotation:
	var yaw := rad_to_deg(grid.get_basis_with_orthogonal_index(orientation).get_euler().y)
	return grid.world_to_grid_rotation(grid.grid_to_world_rotation(BlockData.Rotation.DEG0) + yaw)


func _grid_rotation_to_cell_orientation(grid_rotation: BlockData.Rotation) -> int:
	var basis := Basis.from_euler(Vector3(0.0, deg_to_rad(float(grid_rotation)), 0.0))
	return grid.get_orthogonal_index_from_basis(basis)
