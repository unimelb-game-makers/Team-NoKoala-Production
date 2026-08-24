extends MeshInstance3D

@export var player: Node3D
@export var fade_distance: float = 3.0
var is_faded: bool = false
var _fade_tween: Tween

func _ready() -> void:
	var original_mat = get_active_material(0)
	original_mat = original_mat.duplicate()
	set_surface_override_material(0, original_mat)

func set_faded(fade: bool):
	is_faded = fade
	var mat := get_surface_override_material(0)
	mat.set_shader_parameter("is_faded", is_faded)
	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_LINEAR)
	_fade_tween.tween_property(mat, 'shader_parameter/fade_progress', 0.3, .0)
	print("mat: ", mat, " current fade_progress: ", mat.get_shader_parameter("fade_progress"))

func _process(delta: float) -> void:
	var mat = get_surface_override_material(0)
	if _fade_tween and _fade_tween.is_running():
		print(Time.get_ticks_msec(), " fade_progress: ", mat.get_shader_parameter("fade_progress"))

func _create_shader_tween(node: Node, shader_property: String, value_start: float, value_end: float, duration: float) -> Tween:
	var tween = get_tree().create_tween()
	tween.tween_method(
	func(value): node.material.set_shader_parameter(shader_property, value),  
	value_start,
	value_end,
	duration
  );
	return tween
