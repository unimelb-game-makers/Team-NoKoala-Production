class_name ActionPressedCondition
extends TutorialCondition

## Satisfied when the player presses the input action.
@export_custom(PROPERTY_HINT_INPUT_NAME, "show_builtin") var action: StringName

var _ctx: TutorialContext


func start(ctx: TutorialContext) -> void:
	if not InputMap.has_action(action):
		push_error("ActionPressedCondition: unknown input action '%s'" % action)
		return
	_ctx = ctx
	_ctx.input_received.connect(_on_input)


func stop() -> void:
	if _ctx != null and _ctx.input_received.is_connected(_on_input):
		_ctx.input_received.disconnect(_on_input)
	_ctx = null


func _on_input(event: InputEvent) -> void:
	if not event.is_echo() and event.is_action_pressed(action):
		satisfied.emit()
