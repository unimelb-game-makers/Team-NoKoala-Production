class_name WorldState
extends Node

@export var real_seconds_per_game_day: float = 20.0
const GAME_SECONDS_PER_DAY := 24.0 * 60.0 * 60.0

var game_time_seconds: float = 0.0
var day: int = 1

func _ready() -> void:
	add_to_group("world_state")

func _process(delta: float) -> void:
	var speed := GAME_SECONDS_PER_DAY / real_seconds_per_game_day
	game_time_seconds += delta * speed

	if game_time_seconds >= GAME_SECONDS_PER_DAY:
		game_time_seconds -= GAME_SECONDS_PER_DAY
		day += 1
	
	# print(get_time_string())

func get_hour() -> int:
	return int(game_time_seconds / 3600.0)

func get_minute() -> int:
	return int(game_time_seconds / 60.0) % 60

func get_time_string() -> String:
	return "%02d:%02d" % [get_hour(), get_minute()]
