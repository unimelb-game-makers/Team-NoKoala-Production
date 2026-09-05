class_name FixedClock
extends Node

signal tick(tick_delta: float, ticks_due: int, tick_count: int)

@export_range(1.0, 60.0, 1.0) var tick_rate := 20.0
@export_range(1, 20) var max_catch_up_ticks := 4
@export var running := true

var tick_count := 0
var _accumulator := 0.0


func _ready() -> void:
	add_to_group("fixed_clock")


func _process(delta: float) -> void:
	if not running:
		return

	var tick_delta := 1.0 / tick_rate
	_accumulator += delta

	var n := int(_accumulator / tick_delta)
	if n <= 0:
		return
	n = mini(n, max_catch_up_ticks)

	_accumulator -= n * tick_delta
	tick_count += n
	tick.emit(tick_delta, n, tick_count)


func reset_tick_count() -> void:
	tick_count = 0
	_accumulator = 0.0
