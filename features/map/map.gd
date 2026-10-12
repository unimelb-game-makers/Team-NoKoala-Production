class_name Map
extends Control

@export var regions: Array[MapRegion]
@export var _region_container: Control

var _locations := {}  # maps id to texture
var _discovered := {}  # map id to bool

func _ready() -> void:
	for region in regions:
		var textRect := TextureRect.new()
		textRect.texture = region.reveal
		textRect.position = region.map_position
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
