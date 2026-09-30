class_name Telescope
extends StaticBody3D

@export var view_scene : PackedScene = preload("res://features/telescope/telescope_view_b.tscn")
@onready var overlay = $TelescopeOverlay

func interact() -> void:
	overlay.open(view_scene)
