class_name WorldUIRoot
extends Node

@export var faith_progress_bar: FaithProgressBar
@export var machine_ui: MachineUI


func configure(faith: FaithManager) -> void:
	faith_progress_bar.bind(faith)
