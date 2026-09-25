@tool
extends Node
class_name ResourceAreaManager

@export var grid: Grid
@export var machine_root: Node
@export var machine_factory: MachineFactory

@export_tool_button("Create Machines", "Callable")
var create_machines_button = _create_machines_from_grid


const BAMBOO_CULM_DEFINITION = preload("res://features/factory_system/machines/machine_definitions/bamboo_culm_area.tres")
const IRON_ORE_DEFINITION = preload("res://features/factory_system/machines/machine_definitions/iron_ore_area.tres")

var machine_definition_by_mesh_name: Dictionary = {
	"RA_BAMBOO_CULM": BAMBOO_CULM_DEFINITION,
	"RA_IRON_ORE": IRON_ORE_DEFINITION,
}

func configure(
	p_grid: Grid,
	p_machine_root: Node,
	p_machine_factory: MachineFactory,
) -> void:
	grid = p_grid
	machine_root = p_machine_root
	machine_factory = p_machine_factory

func _create_machines_from_grid() -> void:
	if grid == null or machine_root == null or grid.mesh_library == null or machine_factory == null:
		return

	var resources_created = 0
	for cell in grid.get_used_cells():
		var mesh_name := grid.mesh_library.get_item_name(grid.get_cell_item(cell))
		var definition := machine_definition_by_mesh_name.get(mesh_name) as MachineDefinition
		if definition == null:
			continue

		var assembly := machine_factory.create_machine(definition)
		if assembly == null:
			continue
		assembly.name = definition.resource_path.get_file().get_basename()
		var world_position := grid.cell_to_world(cell)
		assembly.position = machine_root.to_local(world_position)

		machine_root.add_child(assembly)
		if Engine.is_editor_hint():
			assembly.owner = get_tree().edited_scene_root

		# Clear mesh from gridmap cell
		grid.set_cell_item(cell, -1)
		resources_created += 1

	print(resources_created, " resource areas created")
