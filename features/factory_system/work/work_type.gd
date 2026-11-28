class_name WorkType
extends RefCounted

enum Value {
	CRAFTING,
	RITUAL,
	CONSTRUCTION,
	GATHERING,
}

const DESCRIPTIONS := {
	Value.CRAFTING: "Turning raw materials into tools, goods, or equipment.",
	Value.RITUAL: "Performing rituals at ritual machines.",
	Value.CONSTRUCTION: "Building structures and machines.",
	Value.GATHERING: "Harvesting resources from the world.",
}

static func get_description(type: Value) -> String:
	return DESCRIPTIONS.get(type, "")

static func get_display_name(type: Value) -> String:
	return Value.keys()[type].capitalize()
