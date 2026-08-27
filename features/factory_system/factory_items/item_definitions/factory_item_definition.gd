class_name FactoryItemDefinition
extends Resource

@export var item_key: FactoryItemID ## internal identifier like 'iron ore'
@export var item_name: String
@export var texture: Texture2D

enum FactoryItemID {
	IRON_ORE,
	BAMBOO_LOG
}

static var factory_item_definitions = {
	FactoryItemID.IRON_ORE: "res://features/factory_system/factory_items/item_definitions/iron_ore.tres",
	FactoryItemID.BAMBOO_LOG: "res://features/factory_system/factory_items/item_definitions/bamboo_log.tres"
}
