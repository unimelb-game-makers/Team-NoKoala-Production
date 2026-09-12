class_name PathDebugDraw
extends MeshInstance3D

## Draws the sibling `Movement`'s remaining path in the world as a line strip
## with a marker at each waypoint. Add it as a child of a body that has a
## `Movement` component. Purely a debug aid: it computes nothing the mover
## relies on.

## Master switch. Turn off to stop drawing (and skip the per-frame rebuild).
@export var enabled: bool = true
## Only draw in debug builds, so exported release builds never show the path
## even if the node was left enabled.
@export var only_in_debug_builds: bool = true
## Line and marker colour.
@export var color: Color = Color(0.2, 0.9, 1.0)
## Draw on top of walls and machines instead of being occluded by them.
@export var draw_through_walls: bool = true
## Half-size of the little crosshair drawn at each waypoint, in metres.
@export var marker_size: float = 0.12

var _movement: Movement
var _mesh := ImmediateMesh.new()


func _ready() -> void:
	_movement = NodeUtils.get_child_by_type(get_parent(), Movement)

	# Draw in world space: ignore the parent body's position and rotation so the
	# vertices we feed in can be raw global coordinates.
	top_level = true
	global_transform = Transform3D.IDENTITY

	mesh = _mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = color
	mat.no_depth_test = draw_through_walls
	mat.render_priority = 10 if draw_through_walls else 0
	material_override = mat

	if only_in_debug_builds and not OS.is_debug_build():
		enabled = false
	visible = enabled


func _process(_delta: float) -> void:
	if not enabled or _movement == null:
		return

	_mesh.clear_surfaces()
	var path := _movement.get_remaining_path()
	if path.size() < 2:
		visible = false
		return
	visible = true

	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(path.size() - 1):
		_mesh.surface_add_vertex(path[i])
		_mesh.surface_add_vertex(path[i + 1])
	# Skip index 0: that's the body itself, not a waypoint.
	for i in range(1, path.size()):
		_add_marker(path[i])
	_mesh.surface_end()


## Three axis-aligned segments through `p` so waypoints read as points, not just
## kinks in the line.
func _add_marker(p: Vector3) -> void:
	for axis in [Vector3.RIGHT, Vector3.UP, Vector3.FORWARD]:
		_mesh.surface_add_vertex(p - axis * marker_size)
		_mesh.surface_add_vertex(p + axis * marker_size)
