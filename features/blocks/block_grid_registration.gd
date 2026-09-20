@tool
class_name BlockGridRegistration
extends Node

@export var block: Block
@export var grid: Grid

@export_tool_button("Refresh Registration", "Callable")
var refresh_button := refresh

var _watched_block_data: BlockData
var _registered_block: Block
var _registered_grid: Grid
var _registered_block_data: BlockData

func configure(p_block: Block, p_grid: Grid) -> void:
	block = p_block
	grid = p_grid
	if Engine.is_editor_hint():
		_watch_block_data(block.block_data)

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return 
	if block != null:
		_watch_block_data(block.block_data)

func refresh() -> void:

	if Engine.is_editor_hint():
		unregister()
		register()


func is_registered() -> bool:
	return _registered_block != null


func register() -> bool:
	if (
		block == null
		or grid == null
		or _watched_block_data == null
	):
		push_warning("unabled to register due to missing dependencies")
		return false
	if not grid.register_block(block):
		push_warning("unabled to register due to grid conflict")
		return false
	_track_registration()
	print("block registered successsfully")
	return true

func _track_registration() -> void:
	_registered_block = block
	_registered_grid = grid
	_registered_block_data = _watched_block_data


func unregister() -> void:
	if is_instance_valid(_registered_grid) and is_instance_valid(_registered_block):
		_registered_grid.unregister_block(
			_registered_block,
			_registered_block_data,
		)
	_registered_block = null
	_registered_grid = null
	_registered_block_data = null

func _watch_block_data(block_data: BlockData) -> void:
	if block_data == _watched_block_data:
		return
	_disconnect_block_data()
	_watched_block_data = block_data
	if _watched_block_data != null:
		_watched_block_data.changed.connect(refresh)


func _disconnect_block_data() -> void:
	if (
		_watched_block_data != null
		and _watched_block_data.changed.is_connected(refresh)
	):
		_watched_block_data.changed.disconnect(refresh)
	_watched_block_data = null
