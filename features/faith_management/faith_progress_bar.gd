extends Control
class_name FaithProgressBar

@export var faith_manager: FaithManager
@export var low_faith_threshold: float = 20.0
@export var default_faith_colour: Color = Color("#5f5f9a")
@export var low_faith_colour: Color = Color.DARK_RED

@onready var progress_bar: TextureProgressBar = $TextureProgressBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# connect some signal to faith manager (on faith changed?)
	pass # Replace with function body.

func on_faith_changed(new: float, max: float) -> void:
	progress_bar.max_value = max # allows new max to be set later in game progression
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", new, 0.3)
	
	update_colour(new, max)
	
func update_colour(val: float, max: float):
	if val <= low_faith_threshold:
		progress_bar.progress.tint = low_faith_colour
	else:
		progress_bar.progress.tint = default_faith_colour
		
