extends Control
class_name FaithProgressBar

@export var low_faith_threshold: float = 20.0
@export var default_faith_tint: Color = Color.WHITE
@export var low_faith_tint: Color = Color(0.55, 0.25, 0.25)
## TextureRect using faith_bar.gdshader
@export var bar: TextureRect

var _tween: Tween
var _faith_manager: FaithManager

func bind(faith_manager: FaithManager) -> void:
	if _faith_manager == faith_manager: return
	if _faith_manager != null: unbind()
	_faith_manager = faith_manager
	_faith_manager.faith_changed.connect(on_faith_changed)
	on_faith_changed(_faith_manager.current_faith, _faith_manager.max_faith)


func unbind() -> void:
	if (
		_faith_manager != null
		and _faith_manager.faith_changed.is_connected(on_faith_changed)
	):
		_faith_manager.faith_changed.disconnect(on_faith_changed)
	_faith_manager = null
	if _tween != null:
		_tween.kill()
		_tween = null

func _exit_tree() -> void:
	unbind()

func on_faith_changed(new: float, max: float) -> void:
	var ratio := new / max if max > 0.0 else 0.0
	bar.material.set_shader_parameter(&"progress", ratio)  # instant, no tween
	update_colour(new, max)
	
func update_colour(val: float, max: float):
	if val <= low_faith_threshold:
		bar.material.set_shader_parameter(&"tint", low_faith_tint)
	else:
		bar.material.set_shader_parameter(&"tint", default_faith_tint)
		
