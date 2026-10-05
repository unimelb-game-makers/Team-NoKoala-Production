class_name TelescopeView
extends TextureRect

@export var zones : Array[TelescopeZone] = []
signal unlocked_all_zones

func _ready() -> void:
	for zone in zones:
		zone.unlocked.connect(_on_zone_unlocked)

func _on_zone_unlocked() -> void:
	for zone in zones:
		if not zone.is_unlocked:
			return
			
	unlocked_all_zones.emit()
