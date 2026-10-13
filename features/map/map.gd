class_name Map
extends Control

@export var regions: Array[MapRegion]
@export var _region_container: Control
@export var scroll_rhs: TextureRect
@export var scroll_lhs: TextureRect

var _locations := {}  # maps id to icon texture
var _labels := {}  # maps id to label texture
var _undiscovered := {}  # maps id to undiscovered texture
var _discovered := {}  # map id to bool

func _ready() -> void:
	for region in regions:
		var text_rect := TextureRect.new()
		text_rect.texture = region.icon
		text_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		text_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		text_rect.modulate.a = 1.0 if region.discovered_by_default else 0.0
		_region_container.add_child(text_rect)
		
		var undiscovered_rect := TextureRect.new()
		undiscovered_rect.texture = region.undiscovered
		undiscovered_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		undiscovered_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		undiscovered_rect.modulate.a = 0.0 if region.discovered_by_default else 1.0
		_region_container.add_child(undiscovered_rect)
		
		var label_rect := TextureRect.new()
		label_rect.texture = region.label
		label_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		label_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label_rect.modulate.a = 1.0 if region.discovered_by_default else 0.0
		_region_container.add_child(label_rect)
		
		
		_locations[region.id] = text_rect
		_labels[region.id] = label_rect
		_undiscovered[region.id] = undiscovered_rect
		if region.discovered_by_default:
			_discovered[region.id] = true

func discover_region(id: StringName) -> void:
	if _discovered.has(id) or not _locations.has(id) or not _labels.has(id):
		return
	_discovered[id] = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_undiscovered[id], "modulate:a", 0.0, 1.5)
	tween.tween_property(_locations[id], "modulate:a", 1.0, 1.5)
	tween.tween_property(_labels[id], "modulate:a", 1.0, 1.5)
