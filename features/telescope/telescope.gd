class_name TelescopeMachine
extends BasicMachine

@export var view_scene : PackedScene = preload("res://features/telescope/telescope_view_a.tscn")
@onready var overlay = $TelescopeOverlay

func interact() -> void:
	overlay.open(view_scene)
