extends Control
class_name FaithProgressBar

@export var low_faith_threshold: float = 20.0
@export var default_faith_colour: Color = Color("#5f5f9a")
@export var low_faith_colour: Color = Color.DARK_RED
@export var progress_bar: TextureProgressBar

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
	progress_bar.max_value = max
	progress_bar.value = new  # instant, no tween
	update_colour(new, max)
	
func update_colour(val: float, max: float):
	if val <= low_faith_threshold:
		progress_bar.tint_progress = low_faith_colour
	else:
		progress_bar.tint_progress = default_faith_colour
		
