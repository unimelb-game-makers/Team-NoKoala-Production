class_name Map
extends Control

@export var regions: Array[MapRegion]
@export var _region_container: Control
@export var scroll_rhs: TextureRect
@export var scroll_lhs: TextureRect

var _locations := {}  # maps id to icon texture
var _labels := {}  # maps id to label texture
var _player_icons := {}  # maps id to player icon texture
var _undiscovered := {}  # maps id to undiscovered texture
var _discovered := {}  # map id to bool
var _discovered_queue = []

var _current_icon

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
		
		var player_rect := TextureRect.new()
		player_rect.texture = region.player_icon
		player_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		player_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		player_rect.modulate.a = 1.0 if region.discovered_by_default else 0.0
		_region_container.add_child(player_rect)
		
		
		_locations[region.id] = text_rect
		_labels[region.id] = label_rect
		_undiscovered[region.id] = undiscovered_rect
		_player_icons[region.id] = player_rect
		if region.discovered_by_default:
			_discovered[region.id] = true
			_current_icon = _player_icons[region.id]

func discover_region(id: StringName) -> void:
	if not _locations.has(id) or not _labels.has(id) or id == null:
		return
	if _discovered.has(id):
		move_player_icon(id)
		return
	_discovered[id] = true
	_discovered_queue.append(id)
	print("discovered " + id + "!!")
	if visible:
		fade_in_discovered_queue()
		
func fade_in_discovered_queue() -> void:
	if _discovered_queue.is_empty():
		return
	var last_id: StringName = _discovered_queue[-1]
	for id in _discovered_queue:
		var tween := create_tween().set_parallel(true)
		tween.tween_property(_undiscovered[id], "modulate:a", 0.0, 1.5)
		tween.tween_property(_locations[id], "modulate:a", 1.0, 1.5)
		tween.tween_property(_labels[id], "modulate:a", 1.0, 1.5)
	
	_discovered_queue.clear()
	move_player_icon(last_id)

func move_player_icon(id: StringName) -> void:
	if _current_icon == _player_icons[id]:
		return
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_current_icon, "modulate:a", 0.0, 1.0)
	tween.tween_property(_player_icons[id], "modulate:a", 1.0, 1.0)
	_current_icon = _player_icons[id]
