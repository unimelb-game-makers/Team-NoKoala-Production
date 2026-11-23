class_name ProgressionManager
extends Node

signal telescope_stage_advanced(stage: TelescopeStage)


func advance_stage(stage: TelescopeStage) -> void:
	telescope_stage_advanced.emit(stage)
