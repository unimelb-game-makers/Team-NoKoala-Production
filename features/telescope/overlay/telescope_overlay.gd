class_name TelescopeOverlay
extends CanvasLayer

@export var edge_margin: float = 120.0
@export var max_speed: float = 800.0
@export var current_view: TelescopeView

@onready var content: Control = $ScrollContainer/Content
@onready var scroll: ScrollContainer = $ScrollContainer

var _remainder: Vector2 = Vector2.ZERO
const SCALE: float = 1.5

func _ready() -> void:
	hide()

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

func open(view: TelescopeView) -> void:
	if current_view != null:
		current_view.hide()
		
	current_view = view
	if view.get_parent() != content:
		view.reparent(content, false)
	view.show()
	
	var viewport_size := get_viewport().get_visible_rect().size
	var tex_size: Vector2 = current_view.texture.get_size()

	# scale so the image covers the screen with room to scroll
	var scale_by = maxf(viewport_size.x / tex_size.x, viewport_size.y / tex_size.y) * SCALE
	current_view.position = Vector2.ZERO
	current_view.scale = Vector2(scale_by, scale_by)
	content.custom_minimum_size = tex_size * scale_by

	show()
	get_tree().paused = true

	# center the image
	var extra = content.custom_minimum_size - scroll.size
	scroll.scroll_horizontal = int(maxf(extra.x, 0.0) / 2.0)
	scroll.scroll_vertical = int(maxf(extra.y, 0.0) / 2.0)
	_remainder = Vector2.ZERO

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
