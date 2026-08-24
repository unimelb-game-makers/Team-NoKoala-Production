class_name Brain
extends Node

enum MemoryModuleType {
	LAST_KNOWN_PLAYER_POSITION,
	TARGET_POSITION,
}

@export var sensors: Array[Sensor]
@export var behaviour_tree: BehaviourTree
var _memory: Dictionary[MemoryModuleType, Variant]
var actor: Node3D

func _ready() -> void:
	actor = get_parent()
	for sensor in sensors:
		sensor.start(self)

func _process(delta: float) -> void:
	for sensor in sensors:
		sensor.process(self, delta)
	
	if behaviour_tree == null or behaviour_tree.root == null:
		return
	
	if behaviour_tree.root.current_status == BehaviourNode.Status.UNINITIALISED \
	or behaviour_tree.root.current_status == BehaviourNode.Status.RUNNING:
		execute_behaviour_node(behaviour_tree.root, delta)

func get_memory_value(type: MemoryModuleType) -> Variant:
	return _memory.get(type)

func remember_memory_value(type: MemoryModuleType, value: Variant) -> void:
	_memory.set(type, value)

func forget_memory_value(type: MemoryModuleType) -> void:
	_memory.set(type, null)

func execute_behaviour_node(node: BehaviourNode, delta: float) -> BehaviourNode.Status:
	var status := node.current_status
	match status:
		BehaviourNode.Status.RUNNING:
			status = node.process(self, delta)
		_:
			status = node.start(self)
	return status
