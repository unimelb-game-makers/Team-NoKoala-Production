@tool
extends Node
class_name ResourceAreaManager

@export var grid: Grid
@export var machine_root: Node

@export_tool_button("Create Machines", "Callable")
var create_machines_button = _create_machines_from_grid


const BAMBOO_CULM_SCENE = preload("res://features/resource_area/scenes/bamboo_culm_resourcearea.tscn")
const IRON_ORE_SCENE = preload("res://features/resource_area/scenes/iron_ore_resourcearea.tscn")

var machine_scene_by_mesh_name: Dictionary = {
	"RA_BAMBOO_CULM": BAMBOO_CULM_SCENE,
	"RA_IRON_ORE": IRON_ORE_SCENE,
}

func configure(p_grid: Grid, p_machine_root: Node) -> void:
	grid = p_grid
	machine_root = p_machine_root

func _create_machines_from_grid() -> void:
	if grid == null or machine_root == null or grid.mesh_library == null:
		return

	var resources_created = 0
	for cell in grid.get_used_cells():
		var mesh_name := grid.mesh_library.get_item_name(grid.get_cell_item(cell))
		var scene := machine_scene_by_mesh_name.get(mesh_name) as PackedScene
		if scene == null:
			continue

		var assembly := scene.instantiate() as Node3D
		if assembly == null:
			continue
		assembly.name = scene.resource_path.get_file().get_basename()
		var world_position := grid.cell_to_world(cell)
		assembly.position = machine_root.to_local(world_position)

		machine_root.add_child(assembly)
		if Engine.is_editor_hint():
			assembly.owner = get_tree().edited_scene_root

		# Clear mesh from gridmap cell
		grid.set_cell_item(cell, -1)
		resources_created += 1

	print(resources_created, " resource areas created")