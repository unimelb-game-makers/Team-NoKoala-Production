class_name Telescope
extends StaticBody3D

@export var view_scene : PackedScene = preload("res://features/telescope/telescope_view_a.tscn")
@export var overlay : TelescopeOverlay

func interact() -> void:
	if overlay == null:
		return
	overlay.show()
	overlay.open(view_scene)
