extends Control
class_name FaithProgressBar

@export var low_faith_threshold: float = 20.0
@export var default_faith_colour: Color = Color("#5f5f9a")
@export var low_faith_colour: Color = Color.DARK_RED
@export var progress_bar: TextureProgressBar

func _ready() -> void:
	FaithManager.faith_changed.connect(on_faith_changed)
	on_faith_changed(FaithManager.current_faith, FaithManager.max_faith)

func on_faith_changed(new: float, max: float) -> void:
	progress_bar.max_value = max # allows new max to be set later in game progression
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", new, 0.3)
	
	update_colour(new, max)
	
func update_colour(val: float, max: float):
	if val <= low_faith_threshold:
		progress_bar.tint_progress = low_faith_colour
	else:
		progress_bar.tint_progress = default_faith_colour
		
