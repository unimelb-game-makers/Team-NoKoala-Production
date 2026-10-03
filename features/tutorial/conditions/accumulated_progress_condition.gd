class_name AccumulatedProgressCondition
extends TutorialCondition

## Base for conditions that add up a measurement every physics frame until it reaches a
## target. Subclasses override [method _required], [method _reset] and [method _measure].

var _ctx: TutorialContext
var _total := 0.0
var _done := false


func has_progress() -> bool:
	return true


func start(ctx: TutorialContext) -> void:
	_ctx = ctx
	_total = 0.0
	_done = false
	_reset(ctx)
	ctx.ticked.connect(_on_tick)


func stop() -> void:
	if _ctx != null and _ctx.ticked.is_connected(_on_tick):
		_ctx.ticked.disconnect(_on_tick)
	_ctx = null


## Total amount that has to be accumulated.
func _required() -> float:
	return 1.0


## Captures the starting state.
func _reset(_ctx: TutorialContext) -> void:
	pass


## Amount accumulated since the previous tick. Called every tick, even once done.
func _measure(_ctx: TutorialContext) -> float:
	return 0.0


func _on_tick(_delta: float) -> void:
	var amount := _measure(_ctx)
	if _done or amount <= 0.0:
		return
	_total += amount
	var ratio := minf(_total / maxf(_required(), 0.001), 1.0)
	progress_changed.emit(ratio)
	if ratio >= 1.0:
		_done = true
		satisfied.emit()
