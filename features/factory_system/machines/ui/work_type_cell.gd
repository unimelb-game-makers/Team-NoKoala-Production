class_name WorkTypeCell
extends Button

signal clicked(work_type: WorkType.Value)

const DISABLED_MODULATE := Color(0.55, 0.55, 0.55, 1.0)

@export var selection: Control
@export var enabled_badge: Label

var work_type: WorkType.Value


func _ready() -> void:
	pressed.connect(_on_pressed)


func display(type: WorkType.Value, enabled: bool, selected: bool) -> void:
	work_type = type
	
	text = WorkType.get_display_name(type)
	tooltip_text = WorkType.get_description(type)
	self_modulate = Color.WHITE if enabled else DISABLED_MODULATE
	enabled_badge.visible = enabled
	selection.visible = selected

func _on_pressed() -> void:
	clicked.emit(work_type)
