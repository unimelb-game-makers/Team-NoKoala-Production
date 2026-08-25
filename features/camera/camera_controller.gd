extends Camera3D

@export var drag_sensitivity: float = 0.05
var dragging: bool = false
var isFreeEdit: bool = false

# for camera rotation
@onready var spring_arm = get_parent()
@onready var player = get_parent().get_parent()
var mouse_sensitivity := 0.005
const MAX_ZOOM := 5.0
const MIN_ZOOM := -3.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length = clamp(spring_arm.spring_length - 0.5, MIN_ZOOM, MAX_ZOOM)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = clamp(spring_arm.spring_length + 0.5, MIN_ZOOM, MAX_ZOOM)
	elif event is InputEventMouseMotion and dragging:
		if isFreeEdit:
			var delta = Vector3(event.relative.x, 0, event.relative.y) * drag_sensitivity
			position -= delta
		else: 
			player.rotate_y(event.relative.x * mouse_sensitivity)
