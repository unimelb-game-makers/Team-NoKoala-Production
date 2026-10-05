class_name TelescopeUI
extends Control

@export var repair_title_label: Label
@export var repair_details_label: Label
@export var repair_texture: TextureRect
@export var tbd_parent: HBoxContainer
@export var ingredients_parent: VBoxContainer
@export var close_button: Button

@export var recipe: ProductionRecipe

var _rows: Dictionary = {}

const ITEM_PROGRESS = preload("res://features/telescope/item_progress_ui.tscn")

func _ready() -> void:
	close_button.pressed.connect(close)
	hide()
	
func open() -> void:
	show()

func close() -> void:
	hide()

func update_tier() -> void:
	pass
	
func update_recipe() -> void:
	for child in ingredients_parent.get_children():
		child.queue_free()
		
	for input in recipe.inputs:
		var progress_ui := ITEM_PROGRESS.instantiate() as ItemProgressUI
		progress_ui.item = input.item
		progress_ui.quantity_needed = input.amount
		ingredients_parent.add_child(progress_ui)
		_rows[input.item] = progress_ui

func update_quantity(item: FactoryItemDefinition, amount: int) -> void:
	if _rows.has(item):
		_rows[item].update_quantity(amount)
		
