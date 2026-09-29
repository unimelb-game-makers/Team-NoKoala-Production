class_name TelescopeZone
extends Control

var is_hovered: bool = false

func try_unlock() -> void:
	# TO DO: add signals here for progress unlocks
	modulate = Color.GREEN

func is_mouse_over() -> bool:
	return is_hovered

func _on_zone_mouse_entered() -> void:
	is_hovered = true

func _on_zone_mouse_exited() -> void:
	is_hovered = false
