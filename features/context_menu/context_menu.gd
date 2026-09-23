## Popup menu built from a list of ContextMenuActions.
## Runs the chosen action's callback, so callers never deal with item ids.
class_name ContextMenu
extends PopupMenu

var _actions: Array[ContextMenuAction] = []


func _ready() -> void:
	id_pressed.connect(_on_id_pressed)


## Shows the actions at the given screen position. When there are no actions,
## shows `empty_text` as a single disabled entry, or nothing if it is empty.
func open(
	actions: Array[ContextMenuAction],
	screen_position: Vector2,
	empty_text := "",
) -> void:
	close()
	if actions.is_empty():
		if empty_text.is_empty():
			return
		actions = [ContextMenuAction.new(empty_text, Callable(), true)]

	for action in actions:
		var id := _actions.size()
		if action.icon != null:
			add_icon_item(action.icon, action.label, id)
		else:
			add_item(action.label, id)
		set_item_disabled(get_item_index(id), action.disabled)
		_actions.append(action)

	position = Vector2i(screen_position)
	popup()


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
