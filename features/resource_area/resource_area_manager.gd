extends Node
class_name ResourceAreaManager

const RESOURCE_AREA_SCENE = preload("res://features/resource_area/resource_area_machine.tscn")

@export var grid: Grid
@export var machine_root: Node
## GridMap mesh library item name -> the resource area painted with that mesh
@export var definitions_by_mesh_name: Dictionary[String, ResourceAreaDefinition] = {}


func configure(p_grid: Grid, p_machine_root: Node) -> void:
	grid = p_grid
	machine_root = p_machine_root


## Adds a resource area machine on every GridMap cell painted with a known
## mesh. The mesh stays in the GridMap as the visual.
func create_resource_areas() -> Array[MachineAssembly]:
	var created: Array[MachineAssembly] = []
	if grid == null or machine_root == null or grid.mesh_library == null:
		return created

	for cell in grid.get_used_cells():
		var mesh_name := grid.mesh_library.get_item_name(grid.get_cell_item(cell))
		var definition: ResourceAreaDefinition = definitions_by_mesh_name.get(mesh_name)
		if definition == null:
			continue

		var assembly := RESOURCE_AREA_SCENE.instantiate() as MachineAssembly
		var machine := assembly.machine as ResourceAreaMachine
		machine.resource_area_definition = definition
		assembly.name = "%s_%d_%d" % [mesh_name.to_lower(), cell.x, cell.z]
		assembly.position = machine_root.to_local(grid.cell_to_world(cell))

		machine_root.add_child(assembly)
		created.append(assembly)

	print(created.size(), " resource areas created")
	return created
