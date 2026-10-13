class_name Map
extends Control

@export var regions: Array[MapRegion]
@export var _region_container: Control
@export var _empty_map: TextureRect
@export var _base_map: TextureRect
@export var scroll_rhs: TextureRect
@export var scroll_lhs: TextureRect

var _locations := {}  # maps id to texture
var _discovered := {}  # map id to bool
var _windows := {}    # maps id to mask

func _ready() -> void:
	for region in regions:
		var textRect := TextureRect.new()
		textRect.texture = region.icon
		textRect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		textRect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		textRect.modulate.a = 1.0 if region.discovered_by_default else 0.0
		_region_container.add_child(textRect)
		_locations[region.id] = textRect
		if region.discovered_by_default:
			_discovered[region.id] = true

func discover_region(id: StringName) -> void:
	if _discovered.has(id) or not _locations.has(id):
		return
	_discovered[id] = true
	create_tween().tween_property(_locations[id], "modulate:a", 1.0, 1.5)
