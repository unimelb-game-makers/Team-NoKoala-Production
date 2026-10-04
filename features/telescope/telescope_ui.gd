class_name TelescopeUI
extends Control

@export var repair_title_label: Label
@export var repair_details_label: Label
@export var repair_texture: TextureRect
@export var tbd_parent: HBoxContainer
@export var ingredients_parent: VBoxContainer

const ITEM_PROGRESS = preload("res://features/telescope/item_progress_ui.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
