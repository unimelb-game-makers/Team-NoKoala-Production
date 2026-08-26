extends MeshInstance3D

var _fade_tween: Tween

func _ready() -> void:
	var original_mat = get_active_material(0)
	original_mat = original_mat.duplicate()
	set_surface_override_material(0, original_mat)

func set_faded(fade: bool):
	var mat := get_surface_override_material(0)
	mat.set_shader_parameter("is_faded", fade)
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_LINEAR)
	
	# fade OUT vs fade IN
	if fade:
		_fade_tween.tween_property(mat, 'shader_parameter/fade_progress', 0.3, 1.0)
	else:
		_fade_tween.tween_property(mat, 'shader_parameter/fade_progress', 1.0, 1.0)
