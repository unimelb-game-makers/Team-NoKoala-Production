class_name SelectionBox
extends Control

## Draws a 2D screen-space box around a 3D target. The box encloses the
## target's CollisionShape3D children as seen by the active camera, and its
## border keeps the same on-screen width regardless of distance.
## Place it under a CanvasLayer so it draws in screen coordinates.

@export var color: Color = Color(1.0, 0.85, 0.2)
## Border width in screen pixels.
@export var border_width: float = 2.0
## Space between the target's projected bounds and the box, in screen pixels.
@export var padding: float = 4.0
## Target size used when the target has no collision shapes.
@export var fallback_size: Vector3 = Vector3(1, 2, 1)

var target: Node3D

var _local_bounds: AABB
var _screen_rect: Rect2
var _on_screen := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()


func attach(p_target: Node3D) -> void:
	if p_target == null:
		detach()
		return
	target = p_target
	_local_bounds = _get_local_bounds(target)
	show()
	_update_rect()


func detach() -> void:
	target = null
	_on_screen = false
	hide()


func _process(_delta: float) -> void:
	if not visible:
		return
	# A freed target compares equal to null, so check validity rather than null.
	if not is_instance_valid(target):
		detach()
		return
	_update_rect()


func _draw() -> void:
	if _on_screen:
		draw_rect(_screen_rect, color, false, border_width)


func _update_rect() -> void:
	_on_screen = false
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		var rect := Rect2()
		var has_point := false
		for i in 8:
			var world_point := target.global_transform * _local_bounds.get_endpoint(i)
			if camera.is_position_behind(world_point):
				has_point = false
				break
			var screen_point := camera.unproject_position(world_point)
			rect = rect.expand(screen_point) if has_point else Rect2(screen_point, Vector2.ZERO)
			has_point = true
		if has_point:
			_screen_rect = rect.grow(padding)
			_on_screen = true
	queue_redraw()


func _get_local_bounds(node: Node3D) -> AABB:
	var bounds := AABB()
	var found := false
	for child in node.get_children():
		var collision := child as CollisionShape3D
		if collision == null or collision.shape == null or collision.disabled:
			continue
		var shape_bounds: AABB = (
			collision.transform * collision.shape.get_debug_mesh().get_aabb()
		)
		bounds = shape_bounds if not found else bounds.merge(shape_bounds)
		found = true
	if not found:
		bounds = AABB(-fallback_size / 2.0, fallback_size)
	return bounds
