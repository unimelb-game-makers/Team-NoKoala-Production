class_name Block
extends Node3D

@export var block_data: BlockData
@export var transform_root: Node3D

const translucent_alpha := 0.6
static var _red_material: StandardMaterial3D

var _appearance: Appearance = Appearance.NORMAL
var _collision_shapes: Array[Node]
var _collision_shapes_disabled: Array[bool] = []
var _geometry_instances: Array[Node] = []
var _original_materials := {}
var _transparent_materials := {}

enum Appearance {
	NORMAL,
	TRANSLUCENT,
	TRANSLUCENT_RED,
}


static func _static_init():
	_red_material = StandardMaterial3D.new()
	_red_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_red_material.albedo_color = Color(1, 0, 0, translucent_alpha)


func _ready() -> void:
	_cache_shapes()
	_cache_materials()


func get_transform_root() -> Node3D:
	return transform_root if transform_root != null else self


func switch_rotation() -> void:
	block_data.switch_rotation()
	_sync_rotation_visual()


func set_rotation_data(value) -> void:
	block_data.block_rotation = value
	_sync_rotation_visual()


func _sync_rotation_visual() -> void:
	get_transform_root().rotation_degrees.y = block_data.block_rotation


func disable_collisions() -> void:
	_collision_shapes_disabled = []
	_collision_shapes_disabled.resize(_collision_shapes.size())
	for i in range(_collision_shapes.size()):
		var shape = _collision_shapes[i]
		if shape is CollisionShape3D:
			_collision_shapes_disabled[i] = shape.disabled
			shape.set_deferred("disabled", true)
		elif shape is CSGShape3D:
			_collision_shapes_disabled[i] = !shape.use_collision
			shape.use_collision = false


func enable_collisions() -> void:
	for i in range(_collision_shapes.size()):
		var shape = _collision_shapes[i]
		if shape is CollisionShape3D:
			shape.set_deferred("disabled", _collision_shapes_disabled[i])
		elif shape is CSGShape3D:
			shape.use_collision = !_collision_shapes_disabled[i]


func set_appearence(appearance: Appearance) -> void:
	if appearance == _appearance:
		return

	_appearance = appearance
	for geometry in _geometry_instances:
		match appearance:
			Appearance.NORMAL:
				geometry.material_override = null
				_apply_materials(
					geometry,
					_original_materials.get(geometry, [])
				)
			Appearance.TRANSLUCENT:
				geometry.material_override = null
				_apply_materials(
					geometry,
					_transparent_materials.get(geometry, [])
				)
			Appearance.TRANSLUCENT_RED:
				geometry.material_override = _red_material


func _cache_shapes() -> void:
	_collision_shapes = find_children("*", "CollisionShape3D", true, false)
	_collision_shapes.append_array(find_children("*", "CSGShape3D", true, false))


func _cache_materials() -> void:
	_geometry_instances = find_children("*", "GeometryInstance3D", true, false)
	for geometry in _geometry_instances:
		if geometry is MeshInstance3D:
			_cache_mesh_instance(geometry)
		elif geometry is CSGShape3D:
			_cache_csg(geometry)


func _cache_mesh_instance(mesh_instance: MeshInstance3D) -> void:
	var originals: Array[Material] = []
	var transparent: Array[Material] = []

	var mesh := mesh_instance.mesh
	if mesh == null:
		return

	for surface in mesh.get_surface_count():
		var material := mesh_instance.get_surface_override_material(surface)

		if material == null:
			material = mesh.surface_get_material(surface)

		originals.append(material)

		if material is StandardMaterial3D:
			var copy := material.duplicate() as StandardMaterial3D
			copy.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

			var color := copy.albedo_color
			color.a *= translucent_alpha
			copy.albedo_color = color

			transparent.append(copy)
		else:
			transparent.append(material)

	_original_materials[mesh_instance] = originals
	_transparent_materials[mesh_instance] = transparent


func _cache_csg(csg: CSGShape3D) -> void:
	var originals: Array[Material] = []
	var transparent: Array[Material] = []

	var original: Material = csg.material
	originals.append(original)

	var material: StandardMaterial3D
	if original is StandardMaterial3D:
		material = original.duplicate() as StandardMaterial3D
	else:
		material = StandardMaterial3D.new()

	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var color := material.albedo_color
	color.a *= translucent_alpha
	material.albedo_color = color

	transparent.append(material)

	_original_materials[csg] = originals
	_transparent_materials[csg] = transparent


func _apply_materials(geometry: Node, materials: Array) -> void:
	if geometry is MeshInstance3D:
		for i in materials.size():
			geometry.set_surface_override_material(i, materials[i])
	elif geometry is CSGShape3D:
		if "material" in geometry:
			geometry.material = materials[0]
