extends Node

@export var camera: Camera3D
@export var grid: Grid

const DEBUG_PROCESSABLE = preload("res://features/machines/processables/processable.tscn")
@onready var processable_container = $"../Processables"

var _placement_hint_block: Block

func _ready() -> void:
	_placement_hint_block = BlockFactory.create_block()
	grid.add_block_visual(_placement_hint_block)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("rotate"):
		_rotate_block()
	
	if _placement_hint_block != null:
		if not camera: return 
		var cell = cell_at_mouse_position()
		grid.move_block_visual(_placement_hint_block, cell)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_place_block()
	
	if event.is_action_pressed("spawn_processable"):
		debug_spawn_processable()

func _place_block():
	if _placement_hint_block != null:
		var cell = cell_at_mouse_position()
		print(cell)
		if grid.move_block(_placement_hint_block, cell):
			_placement_hint_block = BlockFactory.create_block()
			grid.add_block_visual(_placement_hint_block)

func _rotate_block():
	if _placement_hint_block != null:
		_placement_hint_block.switch_rotation()
		print(_placement_hint_block.block_rotation)

func cell_at_mouse_position() -> Vector3i:
	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	var ray_end := ray_origin + ray_dir * 1000.0
	
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result := grid.get_world_3d().direct_space_state.intersect_ray(query)
	
	if result:
		var hit_pos: Vector3 = result.position
		var cell = grid.local_to_map(hit_pos - (result.normal * (grid.cell_size / 2.0)))
		cell.y = 0
		return cell
	else:
		return Vector3i()

func debug_spawn_processable():
	var processable = DEBUG_PROCESSABLE.instantiate()
	processable.definition = load(ProcessableDefinition.processable_definitions[ProcessableDefinition.ProcessableID.IRON_ORE])
	processable_container.add_child(processable)
	processable.position = cell_at_mouse_position()
	processable.drop_at(processable.position)
