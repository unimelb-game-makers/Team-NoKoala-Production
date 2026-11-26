class_name SpiritUI
extends Control

const CELL_SCENE := preload(
	"res://features/factory_system/machines/ui/work_type_cell.tscn"
)

signal close_requested
signal wander_requested(npc: Npc)

@export var container: VBoxContainer
@export var name_label: Label
@export var current_job_label: Label
@export var close_button: Button
@export var jobs_list: VBoxContainer
@export var wander_button: Button


var npc: Npc
var defintion: NPCDefinition
var _selected: int = -1
var _cells: Array[WorkTypeCell] = []
var _job_board: JobBoard

func _ready() -> void:
	close_button.pressed.connect(close)
	wander_button.pressed.connect(wander)
	hide()

func bind(job_board: JobBoard) -> void:
	_job_board = job_board
	_refresh()
	
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
	current_job_label.text = "Current Job: " + npc.get_current_job_string()
	name_label.text = str(npc.name)
	npc.enabled_work_types_changed.connect(_rebuild_work_types)
	_rebuild_work_types()
	_rebuild_requests()
	show()

func _on_close() -> void:
	if (
		is_instance_valid(npc)
		and npc.enabled_work_types_changed.is_connected(_rebuild_work_types)
	):
		npc.enabled_work_types_changed.disconnect(_rebuild_work_types)
	_clear_grid()
	_clear_requests()
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

func _rebuild_requests() -> void:
	_clear_requests()
	if npc == null or _job_board == null:
		return
	for request in _job_board.get_available_requests(npc.job_consumer):
		if request.job_type() == "wander":
			continue
		# TO DO: update this to a button
		var label := Label.new()
		label.text = str(request.job_type())
		jobs_list.add_child(label)
	
	if jobs_list.get_child_count() == 0:
		var label := Label.new()
		label.text = "No available jobs"
		jobs_list.add_child(label)

func _clear_requests() -> void:
	for child in jobs_list.get_children():
		jobs_list.remove_child(child)
		child.queue_free()

func wander() -> void:
	if npc == null:
		return
	wander_requested.emit(npc)
	current_job_label.text = "Current Job: " + npc.get_current_job_string()
	_rebuild_requests()
