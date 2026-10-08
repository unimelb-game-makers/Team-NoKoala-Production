class_name ProgressionManager
extends Node

signal telescope_stage_advanced(stage: TelescopeStage)

@export var telescope : Telescope

func configure(p_telescope: TelescopeAssembly) -> void:
	telescope = p_telescope.telescope
	_connect_telescope()
	
func _connect_telescope() -> void:
	if not telescope.stage_advanced.is_connected(_on_telescope_stage_advanced):
		telescope.stage_advanced.connect(_on_telescope_stage_advanced)

func _on_telescope_stage_advanced(stage: TelescopeStage) -> void:
	telescope_stage_advanced.emit(stage)
