class_name TelescopeOverlay
extends CanvasLayer

@export var edge_margin: float = 120.0
@export var max_speed: float = 800.0

@onready var content: Control = $ScrollContainer/Content
@onready var scroll: ScrollContainer = $ScrollContainer
var current_view: Control

var _remainder: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	if not visible:
		return
	
	var viewport_size := get_viewport().get_visible_rect().size
	var mouse := get_viewport().get_mouse_position()
	
	var dir = Vector2.ZERO
	dir.x = _edge_strength(mouse.x, viewport_size.x)
	dir.y = _edge_strength(mouse.y, viewport_size.y)
	
	if dir != Vector2.ZERO:
		_scroll_by(dir * max_speed * delta)

func _edge_strength(pos: float, size: float) -> float:
	if pos < edge_margin:
		return -1.0
	elif pos > size - edge_margin:
		return 1.0
	return 0.0

func _scroll_by(amount: Vector2) -> void:
	_remainder += amount
	# scroll container only take ints
	var step = Vector2i(_remainder)
	_remainder -= Vector2(step)
	scroll.scroll_horizontal += step.x
	scroll.scroll_vertical += step.y
	

func open(view_scene: PackedScene) -> void:
	if current_view:
		current_view.queue_free()
	
	current_view = view_scene.instantiate()
	content.add_child(current_view)
	
	# set content to be as big as the png texture
	var tex_size: Vector2 = current_view.texture.get_size()
	current_view.position = Vector2.ZERO
	current_view.custom_minimum_size = tex_size
	content.custom_minimum_size = tex_size
	
	show()
	get_tree().paused = true

func close() -> void:
	hide()
	get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact"):
		for zone: TelescopeZone in current_view.find_children("*", "TelescopeZone", true, false):
			if zone.is_mouse_over():
				zone.try_unlock()
				break
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
