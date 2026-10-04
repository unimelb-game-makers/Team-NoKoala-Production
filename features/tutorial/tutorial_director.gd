class_name TutorialDirector
extends Node

signal step_started(step: TutorialStep, index: int)
signal step_progress(ratio: float)
signal finished(skipped: bool)

@export var sequence: TutorialSequence
@export var auto_start := true

var _ctx := TutorialContext.new()
var _gate: FeatureGate
var _index := -1
var _step: TutorialStep
var _condition: TutorialCondition
var _back_condition: TutorialCondition


func configure(
	gate: FeatureGate,
	factory: FactoryManager,
	dialogue_coordinator: DialogueCoordinator,
	player: Player,
	camera: CameraController,
	placement: MachinePlacementController,
) -> void:
	_gate = gate
	_ctx.gate = gate
	_ctx.factory = factory
	_ctx.dialogue_coordinator = dialogue_coordinator
	_ctx.player = player
	_ctx.camera = camera
	_ctx.placement = placement


func _ready() -> void:
	_ctx.tree = get_tree()
	if auto_start and sequence != null:
		# the player's inventory is created in its own _ready
		start.call_deferred()


func _input(event: InputEvent) -> void:
	if is_running():
		_ctx.input_received.emit(event)


func _physics_process(delta: float) -> void:
	if is_running():
		_ctx.ticked.emit(delta)


func is_running() -> bool:
	return _step != null


func get_step() -> TutorialStep:
	return _step


func get_step_index() -> int:
	return _index


func start(from_index := 0) -> void:
	assert(_gate != null, "TutorialDirector must be configured before start")
	if sequence == null or sequence.steps.is_empty():
		push_warning("TutorialDirector has no steps to run")
		return
	if is_running():
		_end(true)
	_enter_step(from_index)


## Ends the tutorial early and unlocks every feature.
func skip() -> void:
	if is_running():
		_end(true)


func _enter_step(index: int, forward := true) -> void:
	if index >= sequence.steps.size():
		_end(false)
		return
	_index = index
	_step = sequence.steps[index]
	_gate.restrict_to(_step.allowed_features)
	step_started.emit(_step, index)

	if forward and not _step.dialogue_cue.is_empty() and _ctx.dialogue_coordinator != null:
		_ctx.dialogue_coordinator.request_by_cue(_step.dialogue_cue)

	if _step.complete_when == null:
		_advance.call_deferred(index)
		return
	_condition = _step.complete_when
	_condition.progress_changed.connect(_on_progress_changed)
	_condition.satisfied.connect(_advance.bind(index), CONNECT_DEFERRED | CONNECT_ONE_SHOT)
	_condition.start(_ctx)
	if _condition == null or index != _index:
		return # satisfied synchronously and already moved on
	_back_condition = _step.back_when
	if _back_condition != null:
		_back_condition.satisfied.connect(_go_back.bind(index), CONNECT_DEFERRED | CONNECT_ONE_SHOT)
		_back_condition.start(_ctx)


func _advance(from_index: int) -> void:
	if from_index != _index or not is_running():
		return
	_clear_condition()
	_enter_step(from_index + 1)


func _go_back(from_index: int) -> void:
	if from_index != _index or not is_running() or from_index == 0:
		return
	_clear_condition()
	_enter_step(from_index - 1, false)


func _on_progress_changed(ratio: float) -> void:
	step_progress.emit(ratio)


func _clear_condition() -> void:
	if _condition == null:
		return
	_condition.stop()
	_condition.progress_changed.disconnect(_on_progress_changed)
	_disconnect_from_self(_condition)
	_condition = null
	if _back_condition != null:
		_back_condition.stop()
		_disconnect_from_self(_back_condition)
		_back_condition = null


func _disconnect_from_self(condition: TutorialCondition) -> void:
	for connection in condition.satisfied.get_connections():
		if connection.callable.get_object() == self:
			condition.satisfied.disconnect(connection.callable)


func _end(skipped: bool) -> void:
	_clear_condition()
	_step = null
	_index = -1
	_gate.lift()
	finished.emit(skipped)
