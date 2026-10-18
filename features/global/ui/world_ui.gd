class_name WorldUI
extends Node

@export var faith_progress_bar: FaithProgressBar
@export var machine_ui: MachineUI
@export var build_menu_button: Button
@export var build_selection_panel: MachineBuildSelectionPanel
@export var hotbar: Hotbar
@export var tutorial_overlay: TutorialOverlay

var _gate: FeatureGate


func _ready() -> void:
	build_menu_button.pressed.connect(_on_build_menu_pressed)


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
