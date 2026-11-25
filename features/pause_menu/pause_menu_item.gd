class_name PauseMenuItem
extends Button

## A pause menu entry. Selection follows keyboard focus; hovering with the mouse
## takes focus, so arrow keys and mouse share one selection. Selecting
## cross-fades to the highlighted background and slides the item to the left.

@export var title := "":
	set(value):
		title = value
		if is_node_ready():
			_label.text = value
## How far (px) the selected item shifts to the left.
@export var selected_shift := 20.0
@export var transition_duration := 0.18
@export var label_color := Color(0.95, 0.9, 0.82, 0.85)
@export var label_selected_color := Color(1, 0.97, 0.92, 1)

@onready var _visual: Control = $Visual
@onready var _selected_background: CanvasItem = $Visual/SelectedBackground
@onready var _label: Label = $Visual/Label

var _amount := 0.0
var _tween: Tween


func _ready() -> void:
	_label.text = title
	focus_entered.connect(set_selected.bind(true))
	focus_exited.connect(set_selected.bind(false))
	mouse_entered.connect(_on_mouse_entered)
	_apply(0.0)


func set_selected(selected: bool) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_apply, _amount, 1.0 if selected else 0.0, transition_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_mouse_entered() -> void:
	if focus_mode != Control.FOCUS_NONE:
		grab_focus()


func _apply(amount: float) -> void:
	_amount = amount
	_selected_background.modulate.a = amount
	_visual.position.x = -selected_shift * amount
	_label.add_theme_color_override("font_color", label_color.lerp(label_selected_color, amount))
