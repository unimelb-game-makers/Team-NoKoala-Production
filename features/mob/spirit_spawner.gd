class_name SpiritSpawner
extends Node

var _mobs_root: Node
var _fixed_clock: FixedClock
var _job_board: JobBoard
var _reservation_manager: ReservationManager
var _grid: Grid
var _faith_manager: FaithManager
var _warned_missing_root := false

@export var spawn_height := 0.167

const DEMO_SPIRIT_SCENE = preload(
	"res://features/mob/spirit_scenes/demo_spirit.tscn"
)


func configure(
	mobs_root: Node,
	fixed_clock: FixedClock,
	job_board: JobBoard,
	reservation_manager: ReservationManager,
	grid: Grid,
	faith_manager: FaithManager
) -> void:
	_mobs_root = mobs_root
	_fixed_clock = fixed_clock
	_job_board = job_board
	_reservation_manager = reservation_manager
	_grid = grid
	_faith_manager = faith_manager


func spawn_spirit(global_position: Vector3) -> Npc:
	var spirit := create_spirit()
	spirit.configure(
		_fixed_clock,
		_job_board,
		_reservation_manager,
		_grid,
		_faith_manager,
	)

	if _mobs_root != null:
		_mobs_root.add_child(spirit)
	else:
		if not _warned_missing_root:
			printerr("SpiritSpawner has no mobs_root; adding spirits to the scene root")
			_warned_missing_root = true
		get_tree().root.add_child(spirit)
	
	global_position.y = spawn_height
	spirit.global_position = global_position


	return spirit


static func create_spirit() -> Npc:
	return DEMO_SPIRIT_SCENE.instantiate() as Npc
