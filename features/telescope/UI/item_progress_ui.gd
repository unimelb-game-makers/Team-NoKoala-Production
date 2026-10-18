class_name ItemProgressUI
extends Control

@export var item_name: Label
@export var item_progress: Label
@export var item_texture: TextureRect
@export var progress_bar: TextureProgressBar

var item: FactoryItemDefinition
var quantity_needed: int
var quantity_supplied: int = 0

var _tween: Tween

func _ready() -> void:
	_update_ui()

func _update_ui() -> void:
	if item == null:
		return
	item_name.text = item.item_name
	item_texture.texture = item.texture
	item_progress.text = str(quantity_supplied) + "/" + str(quantity_needed)
	progress_bar.max_value = quantity_needed
	progress_bar.value = quantity_supplied

func update_quantity(new_quantity: int) -> void:
	quantity_supplied = new_quantity
	item_progress.text = str(quantity_supplied) + "/" + str(quantity_needed)
	
	if _tween:
		_tween.kill()
		
	_tween = create_tween()
	_tween.tween_property(progress_bar, "value", quantity_supplied, 0.3) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)
