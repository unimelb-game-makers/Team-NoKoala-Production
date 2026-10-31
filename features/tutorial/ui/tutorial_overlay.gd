class_name TutorialOverlay
extends Control

const HIGHLIGHT_MARGIN := 6.0
const HIGHLIGHT_PULSE_SPEED := 4.0
## Screen size used for a world target that has no visuals to measure.
const HIGHLIGHT_FALLBACK_SIZE := Vector2(64, 64)

@export var objective_panel: Control
@export var objective_label: Label
@export var progress_bar: ProgressBar
@export var skip_button: Button
@export var highlight: Panel

var _director: TutorialDirector
## A Control, or a Node3D whose on-screen bounds get highlighted.
var _target: Node


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
	var rect := _get_target_rect()
	if not rect.has_area():
		highlight.hide()
		return
	var margin := Vector2.ONE * HIGHLIGHT_MARGIN
	highlight.global_position = rect.position - margin
	highlight.size = rect.size + margin * 2.0
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
		_target = get_tree().get_first_node_in_group(step.highlight_group)
		if not (_target is Control or _target is Node3D):
			push_warning("TutorialOverlay: no Control or Node3D in group '%s'" % step.highlight_group)
			_target = null
		# tutorial overlay is in the way of faith bar
		if step.highlight_group == "tutorial_faith_bar":
			objective_panel.position.y += 80
		if step.highlight_group == "tutorial_faith_bar_restored":
			objective_panel.position.y -= 80
	set_process(_target != null)


## Screen rect of the target, empty when it is hidden or off-screen.
func _get_target_rect() -> Rect2:
	if not is_instance_valid(_target):
		return Rect2()
	if _target is Control:
		var control := _target as Control
		return Rect2(control.global_position, control.size) if control.is_visible_in_tree() else Rect2()
	var node := _target as Node3D
	var camera := get_viewport().get_camera_3d()
	if camera == null or not node.is_visible_in_tree():
		return Rect2()
	var bounds := _get_world_bounds(node)
	if bounds.size == Vector3.ZERO:
		if camera.is_position_behind(node.global_position):
			return Rect2()
		var center := camera.unproject_position(node.global_position)
		return Rect2(center - HIGHLIGHT_FALLBACK_SIZE / 2.0, HIGHLIGHT_FALLBACK_SIZE)
	var rect := Rect2()
	for i in 8:
		var corner := bounds.get_endpoint(i)
		if camera.is_position_behind(corner):
			return Rect2()
		var point := camera.unproject_position(corner)
		rect = Rect2(point, Vector2.ZERO) if i == 0 else rect.expand(point)
	return rect


## Merged global AABB of every visual under the node.
func _get_world_bounds(node: Node3D) -> AABB:
	var bounds := AABB()
	var found := false
	var pending: Array[Node] = [node]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		pending.append_array(current.get_children())
		var visual := current as VisualInstance3D
		if visual == null or not visual.is_visible_in_tree():
			continue
		var aabb := visual.global_transform * visual.get_aabb()
		bounds = bounds.merge(aabb) if found else aabb
		found = true
	return bounds


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
