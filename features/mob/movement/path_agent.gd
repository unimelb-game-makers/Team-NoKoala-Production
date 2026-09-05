class_name PathAgent
extends Node

## Marks the parent body as something NPC navigation must account for: the
## pathfinder makes the grid cell under it costly to cross, and movers steer
## away from it when they pass nearby. Add one to any body (NPC, player, a
## parked cart) that should be routed around.

## Clearance movers try to keep between themselves and this agent when steering.
@export var avoid_radius: float = 0.9
## Weight multiplier A* pays to cross this agent's grid cell. Higher routes the
## path further around it. A soft cost, not a wall: a plugged corridor still
## yields a path.
@export var avoid_weight: float = 6.0
## Turn off to have pathfinding ignore this agent entirely (e.g. while downed).
@export var active: bool = true

var body: Node3D


func _ready() -> void:
	body = get_parent() as Node3D
	add_to_group("path_agent")
