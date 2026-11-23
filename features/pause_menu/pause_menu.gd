class_name PauseMenu
extends CanvasLayer

## Toggles a game pause with ui_cancel and plays the ink-spread effect over an
## ink-wash restyle of the paused scene.
## Runs with PROCESS_MODE_ALWAYS so it keeps animating while the tree is paused.

signal toggled(is_open: bool)

@export var backdrop: ColorRect
@export var ink: ColorRect
@export var open_duration := 0.9
@export var close_duration := 0.45

var is_open := false

var _ink_material: ShaderMaterial
var _backdrop_material: ShaderMaterial
var _tween: Tween
var _progress := 0.0
var _time := 0.0


func _ready() -> void:
	assert(ink != null and backdrop != null, "PauseMenu requires ink and backdrop ColorRects")
	_ink_material = ink.material as ShaderMaterial
	_backdrop_material = backdrop.material as ShaderMaterial
	assert(_ink_material != null and _backdrop_material != null, "PauseMenu effects require ShaderMaterials")
	_set_progress(0.0)
	ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	var aspect := ink.size.x / ink.size.y if ink.size.y > 0.0 else 1.0
	for material in [_ink_material, _backdrop_material]:
		material.set_shader_parameter("anim_time", _time)
		material.set_shader_parameter("aspect", aspect)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if is_open:
		close()
	elif not get_tree().paused:
		# Something else (cutscene, telescope) already owns the pause.
		open()
	else:
		return
	get_viewport().set_input_as_handled()


func open() -> void:
	if is_open:
		return
	is_open = true
	get_tree().paused = true
	toggled.emit(true)
	ink.mouse_filter = Control.MOUSE_FILTER_STOP
	show()
	_animate_to(1.0, open_duration, Tween.EASE_OUT)


func close() -> void:
	if not is_open:
		return
	is_open = false
	get_tree().paused = false
	toggled.emit(false)
	ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_animate_to(0.0, close_duration, Tween.EASE_IN).finished.connect(hide)


func _exit_tree() -> void:
	if is_open:
		get_tree().paused = false


func _animate_to(target: float, duration: float, ease_type: Tween.EaseType) -> Tween:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_progress, _progress, target, duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(ease_type)
	return _tween


func _set_progress(value: float) -> void:
	_progress = value
	_ink_material.set_shader_parameter("progress", value)
	_backdrop_material.set_shader_parameter("strength", value)
