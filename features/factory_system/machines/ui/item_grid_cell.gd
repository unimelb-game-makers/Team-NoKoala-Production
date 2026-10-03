class_name ItemGridCell
extends Button

signal clicked(item_def: FactoryItemDefinition)

const DISABLED_MODULATE := Color(0.55, 0.55, 0.55, 1.0)

@export var selection: Control
@export var enabled_badge: Label

var item_def: FactoryItemDefinition


func _ready() -> void:
	pressed.connect(_on_pressed)


func display(item: FactoryItemDefinition, enabled: bool, selected: bool) -> void:
	item_def = item

	icon = item_def.texture if item_def != null else null
	text = "" if icon != null else item_def.item_name
	tooltip_text = item_def.item_name
	self_modulate = Color.WHITE if enabled else DISABLED_MODULATE
	enabled_badge.visible = enabled
	selection.visible = selected

func _on_pressed() -> void:
	clicked.emit(item_def)
