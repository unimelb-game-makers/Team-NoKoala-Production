class_name TelescopeUI
extends Control

@export var ITEM_PROGRESS: PackedScene
@export var repair_title_label: Label
@export var repair_details_label: Label
@export var repair_texture: TextureRect
@export var tbd_parent: HBoxContainer
@export var ingredients_parent: VBoxContainer
@export var close_button: Button

@export var recipe: ProductionRecipe

var _rows: Dictionary = {}

func _ready() -> void:
	close_button.pressed.connect(close)
	hide()
	
func open() -> void:
	show()

func close() -> void:
	hide()
	

func update_tier(view: TelescopeView) -> void:
	for child in tbd_parent.get_children():
		child.queue_free()
	
	repair_texture.texture = view.texture
	for zone: TelescopeZone in view.zones:
		var rect = TextureRect.new()
		rect.texture = zone.area_of_interest.texture
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.custom_minimum_size = Vector2(32, 32)
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tbd_parent.add_child(rect)
	
	
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

func update_stage_text(stage: TelescopeStage) -> void:
	repair_title_label.text = stage.title
	repair_details_label.text = stage.details
		
