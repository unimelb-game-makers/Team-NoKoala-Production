class_name WorldUIRoot
extends Node

@export var faith_progress_bar: FaithProgressBar
@export var machine_ui: MachineUI
@export var build_menu_button: Button
@export var build_selection_panel: MachineBuildSelectionPanel
@export var hotbar: Hotbar


func _ready() -> void:
	build_menu_button.pressed.connect(_on_build_menu_pressed)


func configure(faith: FaithManager, placement: MachinePlacementController) -> void:
	faith_progress_bar.bind(faith)
	build_selection_panel.configure(placement)


func _on_build_menu_pressed() -> void:
	if build_selection_panel.visible:
		build_selection_panel.close()
	else:
		build_selection_panel.open()
