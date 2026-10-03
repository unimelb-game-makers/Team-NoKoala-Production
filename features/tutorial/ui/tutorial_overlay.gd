class_name TutorialOverlay
extends Control

const HIGHLIGHT_MARGIN := 6.0
const HIGHLIGHT_PULSE_SPEED := 4.0

@export var objective_panel: Control
@export var objective_label: Label
@export var progress_bar: ProgressBar
@export var skip_button: Button
@export var highlight: Panel

var _director: TutorialDirector
var _target: Control


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color(1.0, 0.85, 0.3)
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	highlight.add_theme_stylebox_override(&"panel", style)
	skip_button.pressed.connect(_on_skip_pressed)
	_hide_all()


func bind(director: TutorialDirector) -> void:
	if _director != null:
		_director.step_started.disconnect(_on_step_started)
		_director.step_progress.disconnect(_on_step_progress)
		_director.finished.disconnect(_on_finished)
	_director = director
	if _director != null:
		_director.step_started.connect(_on_step_started)
		_director.step_progress.connect(_on_step_progress)
		_director.finished.connect(_on_finished)


func _process(_delta: float) -> void:
	if not is_instance_valid(_target) or not _target.is_visible_in_tree():
		highlight.hide()
		return
	var margin := Vector2.ONE * HIGHLIGHT_MARGIN
	highlight.global_position = _target.global_position - margin
	highlight.size = _target.size + margin * 2.0
	highlight.modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() / 1000.0 * HIGHLIGHT_PULSE_SPEED)
	highlight.show()


func _on_step_started(step: TutorialStep, _index: int) -> void:
	objective_label.text = tr(step.objective_text)
	objective_panel.visible = not step.objective_text.is_empty()
	progress_bar.value = 0.0
	progress_bar.visible = step.complete_when != null and step.complete_when.has_progress()
	_target = null
	highlight.hide()
	if not step.highlight_group.is_empty():
		_target = get_tree().get_first_node_in_group(step.highlight_group) as Control
		if _target == null:
			push_warning("TutorialOverlay: no Control in group '%s'" % step.highlight_group)
	set_process(_target != null)


func _on_step_progress(ratio: float) -> void:
	progress_bar.value = ratio


func _on_finished(_skipped: bool) -> void:
	_hide_all()


func _on_skip_pressed() -> void:
	if _director != null:
		_director.skip()


func _hide_all() -> void:
	_target = null
	set_process(false)
	objective_panel.hide()
	highlight.hide()
