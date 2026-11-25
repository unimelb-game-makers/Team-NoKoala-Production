class_name SpiritUI
extends Control

const CELL_SCENE := preload(
	"res://features/factory_system/machines/ui/work_type_cell.tscn"
)

signal close_requested

@export var container: VBoxContainer
@export var close_button: Button


var npc: Npc
var defintion: NPCDefinition
var _selected: int = -1
var _cells: Array[WorkTypeCell] = []

func _ready() -> void:
	close_button.pressed.connect(close)
	hide()
	
func open(target: Npc) -> void:
	close()
	if target == null:
		return
	npc = target
	defintion = npc.definition
	_on_open()


func close() -> void:
	if defintion == null:
		return
	_on_close()
	npc = null
	defintion = null

func _on_open() -> void:
	npc.enabled_work_types_changed.connect(_rebuild_work_types)
	_rebuild_work_types()
	show()

func _on_close() -> void:
	if (
		is_instance_valid(npc)
		and npc.enabled_work_types_changed.is_connected(_rebuild_work_types)
	):
		npc.enabled_work_types_changed.disconnect(_rebuild_work_types)
	_clear_grid()
	hide()


func _build_grid() -> void:
	_clear_grid()
	for type in WorkType.Value.values():
		var cell := CELL_SCENE.instantiate() as WorkTypeCell
		container.add_child(cell)
		cell.clicked.connect(_on_cell_clicked)
		cell.display(type, defintion.worker_capability.can_perform(type), false)
		_cells.append(cell)


func _clear_grid() -> void:
	for cell in _cells:
		container.remove_child(cell)
		cell.queue_free()
	_cells.clear()


func _on_cell_clicked(type: WorkType.Value) -> void:
	if npc == null:
		return
	if type != _selected:
		_selected = type
		_refresh()
		return
	npc.work_types_changed(type)

func _refresh() -> void:
	if npc == null:
		return
	for cell in _cells:
		cell.display(
			cell.work_type,
			defintion.worker_capability.can_perform(cell.work_type),
			cell.work_type == _selected,
		)


func _rebuild_work_types() -> void:
	if npc == null:
		return
	_build_grid()
	var allowed := defintion.worker_capability.allowed_work_types
	if not allowed.has(_selected):
		_selected = allowed[0] if not allowed.is_empty() else -1
	_refresh()
