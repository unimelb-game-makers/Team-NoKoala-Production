class_name WorldUI
extends Node

@export var faith_progress_bar: FaithProgressBar
@export var machine_ui: MachineUI
@export var build_menu_button: Button
@export var build_selection_panel: MachineBuildSelectionPanel
@export var hotbar: Hotbar
@export var map: Map
@export var map_regions: Node


func _ready() -> void:
	build_menu_button.pressed.connect(_on_build_menu_pressed)
	
	for region : MapAreaTrigger in map_regions.get_children():
		region.region_entered.connect(_update_map)

func configure(faith: FaithManager, placement: MachinePlacementController) -> void:
	faith_progress_bar.bind(faith)
	build_selection_panel.configure(placement)


func _on_build_menu_pressed() -> void:
	if build_selection_panel.visible:
		build_selection_panel.close()
	else:
		build_selection_panel.open()

func toggle_map() -> void:
	map.visible = not map.visible
	map.fade_in_discovered_queue()
	
func _update_map(id: StringName) -> void:
	print("unlocked " + id + "!!")
	map.discover_region(id)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_map"):
		toggle_map()
		get_viewport().set_input_as_handled()
		
