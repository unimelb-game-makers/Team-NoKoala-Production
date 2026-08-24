class_name ProcessableDefinition
extends Resource

@export var process_key: ProcessableID ## internal identifier like 'iron ore'
@export var item_name: String
@export var texture: Texture2D

enum ProcessableID {
	IRON_ORE,
	BAMBOO_LOG
}

static var processable_definitions = {
	ProcessableID.IRON_ORE: "res://features/machines/processables/processable_resources/iron_ore.tres",
	ProcessableID.BAMBOO_LOG: "res://features/machines/processables/processable_resources/bamboo_log.tres"
}
