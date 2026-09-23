## One entry in a ContextMenu. `callback` runs when the entry is chosen.
class_name ContextMenuAction

var label: String
var callback: Callable
var disabled: bool
var icon: Texture2D


func _init(
	p_label: String,
	p_callback: Callable,
	p_disabled := false,
	p_icon: Texture2D = null,
) -> void:
	label = p_label
	callback = p_callback
	disabled = p_disabled
	icon = p_icon
