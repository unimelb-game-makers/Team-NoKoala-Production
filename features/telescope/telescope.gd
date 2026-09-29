extends StaticBody3D

@export var view_scene : PackedScene = preload("res://features/telescope/telescope_view_a.tscn")
@onready var overlay = $TelescopeOverlay

func _ready() -> void:
	overlay.open(view_scene)
