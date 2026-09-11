class_name PlacementGrid
extends MeshInstance3D

const SHADER := preload("res://shaders/placement_grid/placement_grid.gdshader")

## World units from the cursor where the grid becomes fully transparent.
@export var outer_radius: float = 7.0
## World units from the cursor that stay fully opaque before the fade starts.
@export var inner_radius: float = 3.0
## Small lift to avoid z-fighting with the ground plane.
@export var ground_offset: float = 0.02
## Seconds for the show/hide fade.
@export var fade_time: float = 0.12

var _material: ShaderMaterial
var _fade_tween: Tween

func _ready() -> void:
	# Quad big enough to always contain the fade circle.
	var span := (outer_radius + 1.0) * 2.0
	var plane := PlaneMesh.new()          # PlaneMesh already lies in the XZ plane
	plane.size = Vector2(span, span)
	mesh = plane

	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter("inner_radius", inner_radius)
	_material.set_shader_parameter("outer_radius", outer_radius)
	_material.set_shader_parameter("global_alpha", 0.0)
	# Draw after opaque geometry; combined with depth_draw_never in the shader
	# this keeps the overlay from fighting the ground.
	_material.render_priority = 1
	material_override = _material

	cast_shadow = SHADOW_CASTING_SETTING_OFF
	visible = false

## Call every frame with the raycast hit point on the ground.
func set_cursor(world_pos: Vector3) -> void:
	global_position = Vector3(world_pos.x, world_pos.y + ground_offset, world_pos.z)

func show_grid() -> void:
	visible = true
	_tween_alpha(1.0)

func hide_grid() -> void:
	_tween_alpha(0.0, func() -> void: visible = false)

func _tween_alpha(target: float, on_done: Callable = Callable()) -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_method(
		func(v: float) -> void: _material.set_shader_parameter("global_alpha", v),
		_material.get_shader_parameter("global_alpha"),
		target,
		fade_time,
	)
	if on_done.is_valid():
		_fade_tween.tween_callback(on_done)
