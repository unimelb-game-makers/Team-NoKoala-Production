class_name OptionsMenu
extends CanvasLayer

## Options screen opened from the pause menu. Exactly one element (a volume
## slider or a button) is selected at a time: selection follows keyboard focus,
## and hovering with the mouse moves focus. Up/down move between elements,
## left/right adjust the slider.
##
## The sliders preview the volume live. Apply saves it; Back (or Esc) returns
## to the pause menu and reverts anything not applied.

signal closed

## Size the layout was designed at; it is scaled to fit the window.
const DESIGN_SIZE := Vector2(1404, 848)

@export var layout: Control
@export var volume_slider: HSlider
@export var volume_value_label: Label
@export var sfx_slider: HSlider
@export var sfx_value_label: Label
@export var apply_button: Button
@export var back_button: Button
@export var button_style: StyleBox
@export var button_selected_style: StyleBox
@export var button_outline_color := Color("#FFFFFF")
@export var button_selected_outline_color := Color("#F8CB8B")


func _ready() -> void:
	hide()
	get_viewport().size_changed.connect(_fit_layout)
	_fit_layout()

	volume_slider.value_changed.connect(_on_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	apply_button.pressed.connect(_on_apply_pressed)
	back_button.pressed.connect(close)

	var items: Array[Control] = [volume_slider, sfx_slider, apply_button, back_button]
	for i in items.size():
		var item := items[i]
		var prev := items[(i - 1 + items.size()) % items.size()]
		var next := items[(i + 1) % items.size()]
		item.focus_neighbor_top = item.get_path_to(prev)
		item.focus_neighbor_bottom = item.get_path_to(next)
		item.focus_previous = item.get_path_to(prev)
		item.focus_next = item.get_path_to(next)
		if item is Button:
			# The slider uses left/right for its value; buttons stay put.
			item.focus_neighbor_left = item.get_path_to(item)
			item.focus_neighbor_right = item.get_path_to(item)
		item.mouse_entered.connect(_on_item_hovered.bind(item))
		item.focus_entered.connect(_set_item_selected.bind(item, true))
		item.focus_exited.connect(_set_item_selected.bind(item, false))
		_set_item_selected(item, false)


func open() -> void:
	volume_slider.set_value_no_signal(GameSettings.music_volume)
	sfx_slider.set_value_no_signal(GameSettings.sfx_volume)
	_update_value_labels()
	show()
	volume_slider.grab_focus()


func close() -> void:
	if not visible:
		return
	# Drop any unapplied preview.
	GameSettings.apply_music_volume(GameSettings.music_volume)
	GameSettings.apply_sfx_volume(GameSettings.sfx_volume)
	var focus := get_viewport().gui_get_focus_owner()
	if focus != null and is_ancestor_of(focus):
		focus.release_focus()
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		# Nothing focused (e.g. after clicking the background): select the slider.
		volume_slider.grab_focus()
		get_viewport().set_input_as_handled()


func _fit_layout() -> void:
	var view := get_viewport().get_visible_rect().size
	var s := minf(view.x / DESIGN_SIZE.x, view.y / DESIGN_SIZE.y)
	layout.scale = Vector2(s, s)
	layout.position = (view - DESIGN_SIZE * s) * 0.5


func _on_item_hovered(item: Control) -> void:
	if visible:
		item.grab_focus()


## Buttons swap their style here; the slider draws its own selected thumb.
func _set_item_selected(item: Control, selected: bool) -> void:
	if item is Button:
		var style := button_selected_style if selected else button_style
		for state in ["normal", "hover", "pressed", "hover_pressed"]:
			item.add_theme_stylebox_override(state, style)
		item.add_theme_color_override("font_outline_color",
			button_selected_outline_color if selected else button_outline_color)


func _on_volume_changed(value: float) -> void:
	_update_value_labels()
	GameSettings.apply_music_volume(int(value))


func _on_sfx_volume_changed(value: float) -> void:
	_update_value_labels()
	GameSettings.apply_sfx_volume(int(value))


func _update_value_labels() -> void:
	volume_value_label.text = str(int(volume_slider.value))
	sfx_value_label.text = str(int(sfx_slider.value))


func _on_apply_pressed() -> void:
	GameSettings.music_volume = int(volume_slider.value)
	GameSettings.sfx_volume = int(sfx_slider.value)
	GameSettings.save_settings()
