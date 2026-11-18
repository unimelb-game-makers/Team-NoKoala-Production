class_name WorldUI
extends Node

@export var faith_progress_bar: FaithProgressBar
@export var machine_ui: MachineUI
@export var build_menu_button: Button
@export var build_selection_panel: MachineBuildSelectionPanel
@export var hotbar: Hotbar
@export var map: Map
@export var map_regions: Node
@export var tutorial_overlay: TutorialOverlay
@export var item_stack_list_panel: ItemStackListPanel
@export var cutscene_player: VideoStreamPlayer

var _gate: FeatureGate
var _was_paused := false


func _ready() -> void:
	build_menu_button.pressed.connect(_on_build_menu_pressed)
	cutscene_player.finished.connect(_on_cutscene_finished)

	if map_regions == null:
		return
	for region : MapAreaTrigger in map_regions.get_children():
		region.region_entered.connect(_update_map)


func play_cutscene(stream: VideoStream) -> bool:
	if cutscene_player.is_playing() or stream == null:
		return false
	cutscene_player.stream = stream
	cutscene_player.show()
	_was_paused = get_tree().paused
	get_tree().paused = true
	cutscene_player.play()
	return true


func _on_cutscene_finished() -> void:
	cutscene_player.hide()
	get_tree().paused = _was_paused


func _exit_tree() -> void:
	if cutscene_player.visible:
		get_tree().paused = _was_paused

func configure(
	faith: FaithManager,
	placement: MachinePlacementController,
	gate: FeatureGate = null,
	tutorial: TutorialDirector = null,
) -> void:
	faith_progress_bar.bind(faith)
	build_selection_panel.configure(placement)
	_bind_gate(gate)
	tutorial_overlay.bind(tutorial)


func _bind_gate(gate: FeatureGate) -> void:
	if _gate != null:
		_gate.changed.disconnect(_apply_gate)
	_gate = gate
	if _gate != null:
		_gate.changed.connect(_apply_gate)
	_apply_gate()


func _apply_gate() -> void:
	var build_allowed := FeatureGate.check(_gate, GameFeature.Id.BUILD_MENU)
	build_menu_button.disabled = not build_allowed
	if not build_allowed:
		build_selection_panel.close()
	if not FeatureGate.check(_gate, GameFeature.Id.MACHINE_UI):
		machine_ui.close()
	hotbar.set_interactive(FeatureGate.check(_gate, GameFeature.Id.HOTBAR))


func _on_build_menu_pressed() -> void:
	if build_selection_panel.visible:
		build_selection_panel.close()
	else:
		build_selection_panel.open()

func toggle_map() -> void:
	map.visible = not map.visible
	map.fade_in_discovered_queue()
	
func _update_map(id: StringName) -> void:
	map.discover_region(id)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_map"):
		toggle_map()
		get_viewport().set_input_as_handled()
		
