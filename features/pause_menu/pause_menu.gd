class_name PauseMenu
extends CanvasLayer

## Toggles a game pause with ui_cancel and plays the ink-spread effect over an
## ink-wash restyle of the paused scene.
## Runs with PROCESS_MODE_ALWAYS so it keeps animating while the tree is paused.
## The menu items are selected with the arrow keys or the mouse.

signal toggled(is_open: bool)

@export var backdrop: ColorRect
@export var ink: ColorRect
@export var menu: Control
@export var resume_button: PauseMenuItem
@export var options_button: PauseMenuItem
@export var exit_button: PauseMenuItem
@export var options_menu: OptionsMenu
@export var open_duration := 0.9
@export var close_duration := 0.45
## How far (px) the menu slides in from the right while it fades in.
@export var menu_slide := 60.0

var is_open := false

var _ink_material: ShaderMaterial
var _backdrop_material: ShaderMaterial
var _tween: Tween
var _progress := 0.0
var _time := 0.0
var _menu_offset_left := 0.0
var _menu_offset_right := 0.0


func _ready() -> void:
	assert(ink != null and backdrop != null, "PauseMenu requires ink and backdrop ColorRects")
	_ink_material = ink.material as ShaderMaterial
	_backdrop_material = backdrop.material as ShaderMaterial
	assert(_ink_material != null and _backdrop_material != null, "PauseMenu effects require ShaderMaterials")
	_menu_offset_left = menu.offset_left
	_menu_offset_right = menu.offset_right
	_setup_buttons()
	_set_progress(0.0)
	ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_menu_interactive(false)
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
	if options_menu.visible:
		return
	# Arrow keys with nothing focused (e.g. after clicking the backdrop) select
	# the first item again.
	if is_open and (event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down")):
		if not _buttons().has(get_viewport().gui_get_focus_owner()):
			resume_button.grab_focus()
			get_viewport().set_input_as_handled()
		return
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
	_set_menu_interactive(true)
	resume_button.grab_focus()
	_animate_to(1.0, open_duration, Tween.EASE_OUT)


func close() -> void:
	if not is_open:
		return
	is_open = false
	get_tree().paused = false
	toggled.emit(false)
	ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_menu_interactive(false)
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
	# The menu appears once the ink has mostly spread, sliding in from the right.
	var menu_t := smoothstep(0.45, 1.0, value)
	menu.modulate.a = menu_t
	var slide := (1.0 - menu_t) * menu_slide
	menu.offset_left = _menu_offset_left + slide
	menu.offset_right = _menu_offset_right + slide


func _buttons() -> Array[PauseMenuItem]:
	return [resume_button, options_button, exit_button]


func _setup_buttons() -> void:
	resume_button.pressed.connect(close)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	options_menu.closed.connect(_on_options_closed)

	var buttons := _buttons()
	for i in buttons.size():
		var button := buttons[i]
		var prev := buttons[(i - 1 + buttons.size()) % buttons.size()]
		var next := buttons[(i + 1) % buttons.size()]
		# Wrap around vertically and keep focus inside the menu.
		button.focus_neighbor_top = button.get_path_to(prev)
		button.focus_neighbor_bottom = button.get_path_to(next)
		button.focus_neighbor_left = button.get_path_to(button)
		button.focus_neighbor_right = button.get_path_to(button)
		button.focus_previous = button.get_path_to(prev)
		button.focus_next = button.get_path_to(next)


func _set_menu_interactive(interactive: bool) -> void:
	for button in _buttons():
		button.mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
		button.focus_mode = Control.FOCUS_ALL if interactive else Control.FOCUS_NONE
		if not interactive:
			button.release_focus()


func _on_options_pressed() -> void:
	# The options screen has its own background, so hide the ink layers under it.
	_set_menu_interactive(false)
	_set_effects_visible(false)
	options_menu.open()


func _on_options_closed() -> void:
	_set_effects_visible(true)
	_set_menu_interactive(true)
	options_button.grab_focus()


func _set_effects_visible(effects_visible: bool) -> void:
	backdrop.visible = effects_visible
	ink.visible = effects_visible
	menu.visible = effects_visible


func _on_exit_pressed() -> void:
	get_tree().quit()
