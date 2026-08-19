extends Camera3D

@export var drag_sensitivity: float = 0.05
var dragging: bool = false
var player: Player

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		var delta = Vector3(event.relative.x, 0, event.relative.y) * drag_sensitivity
		position -= delta
