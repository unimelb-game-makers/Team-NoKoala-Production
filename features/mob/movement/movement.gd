class_name Movement
extends Node

@export var move_speed: float = 1.0
@export var rotation_speed: float = 5.0
@export var stop_distance: float = 0.01
## How close the body must get to an intermediate path waypoint before it
## advances to the next one. Looser than `stop_distance` so mobs don't stall
## trying to hit exact cell centres.
@export var waypoint_distance: float = 0.15
## Re-run pathfinding this often (seconds) while moving, so a mob reacts to
## machines placed after it set out. Set to 0 to disable periodic replanning.
@export var replan_interval: float = 0.5

var status: Status = Status.STOPPED

var character_body: CharacterBody3D
var next_node: Vector3
var destination: Vector3

var _path: PackedVector3Array = PackedVector3Array()
var _path_index: int = 0
var _replan_timer: float = 0.0
var _pathfinder: Pathfinder

signal move_started
signal move_ended
signal move_failed

enum Status {
	MOVING,
	STOPPED,
	FAILED,
}


func _ready() -> void:
	character_body = get_parent()
	_pathfinder = get_tree().get_first_node_in_group("pathfinder")


func _physics_process(delta: float) -> void:
	if status != Status.MOVING:
		return

	if replan_interval > 0.0:
		_replan_timer += delta
		if _replan_timer >= replan_interval:
			_replan_timer = 0.0
			if not _recompute_path(destination):
				_fail_move()
				return

	var is_last_waypoint := _path_index >= _path.size() - 1
	var tolerance := stop_distance if is_last_waypoint else waypoint_distance
	if character_body.global_position.distance_to(next_node) <= tolerance:
		_path_index += 1
		if _path_index >= _path.size():
			_end_move()
			return
		next_node = _flatten(_path[_path_index])

	var direction := character_body.global_position.direction_to(next_node)
	character_body.velocity = direction * move_speed
	if not character_body.is_on_floor():
		character_body.velocity.y = character_body.velocity.y + (character_body.get_gravity().y * delta)
	character_body.move_and_slide()

	var look_target = Vector3(next_node.x, character_body.global_position.y, next_node.z)
	if character_body.global_position.distance_to(look_target) > 0.01:
		var target_transform = character_body.global_transform.looking_at(look_target, Vector3.UP)
		character_body.global_transform.basis = character_body.global_transform.basis.slerp(
			target_transform.basis,
			rotation_speed * delta
		)


func _end_move():
	character_body.velocity = Vector3.ZERO
	character_body.move_and_slide()
	if status != Status.STOPPED:
		status = Status.STOPPED
		move_ended.emit()


func start_moving_to(position: Vector3):
	destination = position
	_replan_timer = 0.0
	if not _recompute_path(position):
		_fail_move()
		return
	if status != Status.MOVING:
		status = Status.MOVING
		move_started.emit()


func stop_moving():
	_end_move()


func _fail_move() -> void:
	character_body.velocity = Vector3.ZERO
	character_body.move_and_slide()
	_path = PackedVector3Array()
	_path_index = 0
	status = Status.FAILED
	move_failed.emit()


func within_stop_distance(position: Vector3):
	var distance := character_body.global_position.distance_to(position)
	return distance <= stop_distance


func _recompute_path(p_destination: Vector3) -> bool:
	if _pathfinder == null:
		_pathfinder = get_tree().get_first_node_in_group("pathfinder")

	var new_path: PackedVector3Array
	if _pathfinder != null:
		new_path = _pathfinder.find_path(character_body.global_position, p_destination)
	else:
		new_path = PackedVector3Array([p_destination])  # Fallback: straight line.

	if new_path.is_empty():
		return false

	_path = new_path
	_path_index = 0
	next_node = _flatten(_path[0])
	return true


func _flatten(v: Vector3) -> Vector3:
	return Vector3(v.x, character_body.global_position.y, v.z)
