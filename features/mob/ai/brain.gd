class_name Brain
extends Node

@onready var bt_player: BTPlayer = $BTPlayer

const LAST_KNOWN_PLAYER_POSITION := &"LAST_KNOWN_PLAYER_POSITION"
const TARGET_POSITION := &"TARGET_POSITION"

@export var sensors: Array[Sensor]
var actor: Node3D

func _ready() -> void:
	actor = get_parent()
	for sensor in sensors:
		sensor.start(self)

func _process(delta: float) -> void:
	for sensor in sensors:
		sensor.process(self, delta)
	
func get_memory_value(key: StringName) -> Variant:
	return bt_player.blackboard.get_var(key)

func remember_memory_value(key: StringName, value: Variant) -> void:
	bt_player.blackboard.set_var(key, value)

func forget_memory_value(key: StringName) -> void:
	bt_player.blackboard.erase_var(key)
