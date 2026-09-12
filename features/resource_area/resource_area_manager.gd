@tool
extends Node
class_name ResourceAreaManager

@export var grid: Grid
@export var factory_manager: FactoryManager

@export_tool_button("Create Machines", "Callable")
var create_machines_button = _create_machines_from_grid

var _floating_assembly: MachineAssembly
var _selected_machine: MachineFactory.MachineType = MachineFactory.MachineType.DEMO
var _last_rotation: BlockData.Rotation = BlockData.Rotation.DEG0

const RESOURCE_AREA_SCENE = preload("res://features/resource_area/resource_area_machine.tscn")
const BAMBOO_CULM_DEFINITION = preload("res://features/resource_area/resource_area_definitions/spawner_bamboo_culm_definition.tres")
const IRON_ORE_DEFINITION = preload("res://features/resource_area/resource_area_definitions/spawner_iron_ore_definition.tres")
const RESOURCE_AREA_DEFINITION = preload("res://features/factory_system/machines/machine_definitions/machine_definition.gd")

enum MACHINE_MESHES {
	RA_BAMBOO_CULM,
	RA_IRON_ORE
}

#var index_to_machine_mesh

var machine_mesh_to_resource_definition: Dictionary = {
	"RA_BAMBOO_CULM": BAMBOO_CULM_DEFINITION,
	"RA_IRON_ORE": IRON_ORE_DEFINITION,
}

func _create_machines_from_grid() -> void:
#	_floating_assembly = null
	var cells = grid.get_used_cells()

	#print(MACHINE_MESHES)
	for cell in cells:
		if grid.get_cell_item(cell) not in MACHINE_MESHES.values(): continue
		#var resource_area: MachineAssembly = RESOURCE_AREA_SCENE.instantiate()
		
		'''
		add_child(resource_area)
		resource_area.owner = get_tree().edited_scene_root
		var machine_node = resource_area.get_node("Machine")
		machine_node.resource_area_definition = ra_definition
		machine_node.sprite.texture = ra_definition.texture
		machine_node._processing_recipe = ra_definition.spawner_recipe
		'''

		var ra_definition = machine_mesh_to_resource_definition.get(grid.mesh_library.get_item_name(grid.get_cell_item(cell)))
		_floating_assembly = create_machine()
		var machine_node = _floating_assembly.get_node("Machine")
		machine_node.resource_area_definition = ra_definition
		machine_node.sprite.texture = ra_definition.texture
		machine_node._processing_recipe = ra_definition.spawner_recipe
		_floating_assembly.block.disable_collisions()
		grid.add_block_visual(_floating_assembly.block)
		_floating_assembly.block.set_rotation_data(_last_rotation)
		_floating_assembly.owner = get_tree().edited_scene_root
		machine_node.owner = get_tree().edited_scene_root
		_floating_assembly.block.owner = get_tree().edited_scene_root
		

		
		if not confirm_placement(cell): continue
		
		
		#cancel_placement()
	
		
	#grid.clear()
func cancel_placement() -> void:
	if _floating_assembly != null:
		_floating_assembly.queue_free()
		_floating_assembly = null


func create_machine() -> MachineAssembly:
	var scene: PackedScene = RESOURCE_AREA_SCENE
	var assembly := scene.instantiate() as MachineAssembly
	assert(assembly != null, "Machine assembly scene must have a MachineAssembly root")
	assert(assembly.block != null, "MachineAssembly requires a Block component")
	assert(assembly.machine != null, "MachineAssembly requires a Machine component")
	assert(assembly.machine.definition != null, "Machine requires a MachineDefinition")

	var validation_errors := assembly.machine.definition.get_validation_errors()
	assert(
		validation_errors.is_empty(),
		"Invalid machine definition:\n- %s" % "\n- ".join(validation_errors),
	)

	assembly.block.block_data = create_block_data(assembly.machine.definition)
	return assembly


func create_block_data(definition: MachineDefinition) -> BlockData:
	var block_data := BlockData.new()


	for machine_cell in definition.cells:
		block_data.footprint.append(machine_cell.local_cell_offset)
		if machine_cell.can_overlap:
			block_data.overlap_cells.append(machine_cell.local_cell_offset)
	return block_data
	

func confirm_placement(cell) -> bool:
	if _floating_assembly == null:
		return false

	if not grid.move_block(_floating_assembly.block, cell):
		return false

	_floating_assembly.machine.center_position = cell
	#if not factory_manager.register_machine(_floating_assembly.machine):
	#	grid.remove_block(_floating_assembly.block)
		#return false
	
	_floating_assembly.block.enable_collisions()
	_floating_assembly.block.set_appearence(Block.Appearance.NORMAL)
	
	_floating_assembly = null
	
	return true
