## Popup menu built from a list of ContextMenuActions.
## Runs the chosen action's callback, so callers never deal with item ids.
class_name ContextMenu
extends PopupMenu

var _actions: Array[ContextMenuAction] = []


func _ready() -> void:
	id_pressed.connect(_on_id_pressed)


## Shows the actions at the given screen position. Null entries are skipped.
## Returns false, without showing anything, when there are no actions.
func open(actions: Array[ContextMenuAction], screen_position: Vector2) -> bool:
	close()
	for action in actions:
		if action == null:
			continue
		var id := _actions.size()
		if action.icon != null:
			add_icon_item(action.icon, action.label, id)
		else:
			add_item(action.label, id)
		set_item_disabled(get_item_index(id), action.disabled)
		_actions.append(action)

	if _actions.is_empty():
		return false
	position = Vector2i(screen_position)
	popup()
	return true


func close() -> void:
	hide()
	clear()
	_actions.clear()


func _on_id_pressed(id: int) -> void:
	if id < 0 or id >= _actions.size():
		return
	var action := _actions[id]
	if action.callback.is_valid():
		action.callback.call()
