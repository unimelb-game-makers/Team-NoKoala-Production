class_name TelescopeZone
extends Control

@export var area_of_interest: Sprite2D

var is_hovered: bool = false
var is_unlocked: bool = false

signal unlocked

func try_unlock() -> void:
	# TO DO: add signals here for progress unlocks
	if is_unlocked:
		return
	is_unlocked = true
	unlocked.emit()
	area_of_interest.modulate = Color.GREEN

func is_mouse_over() -> bool:
	return is_hovered

func _on_zone_mouse_entered() -> void:
	is_hovered = true

func _on_zone_mouse_exited() -> void:
	is_hovered = false
