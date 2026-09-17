class_name UIRoot
extends Node

@export var faith_progress_bar: FaithProgressBar

var _context: WorldContext


func _ready() -> void:
	assert(faith_progress_bar != null, "UIRoot requires a FaithProgressBar")


func bind_world(context: WorldContext) -> void:
	if _context == context:
		return

	unbind_world()
	_context = context
	faith_progress_bar.bind(context.faith)


func unbind_world() -> void:
	if faith_progress_bar != null:
		faith_progress_bar.unbind()
	_context = null
