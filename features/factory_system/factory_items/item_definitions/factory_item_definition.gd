class_name FactoryItemDefinition
extends Resource

@export var item_key: FactoryItemID ## internal identifier like 'iron ore'
@export var item_name: String
@export var texture: Texture2D
@export var max_stack: int = 64

enum FactoryItemID {
	IRON_ORE,
	BAMBOO_CULM,
	RAW_FLAX,
	BAMBOO_PLANK,
	RAW_CLAY,
	RAW_STONE,
	BAMBOO_JOINT,
	BRICKS_STONE,
	CLAY_BEADS,
	ROPE_FLAX,
	DOLL_WOODEN,
	GETA_WOODEN,
	NECKLACE_CLAY,
}

static var factory_item_definitions = {
	FactoryItemID.IRON_ORE: "res://features/factory_system/factory_items/item_definitions/iron_ore.tres",
	FactoryItemID.BAMBOO_CULM: "res://features/factory_system/factory_items/item_definitions/bamboo_culm.tres",
	FactoryItemID.RAW_FLAX: "res://features/factory_system/factory_items/item_definitions/flax.tres",
	FactoryItemID.BAMBOO_PLANK: "res://features/factory_system/factory_items/item_definitions/bamboo_plank.tres",
	FactoryItemID.RAW_CLAY: "res://features/factory_system/factory_items/item_definitions/clay.tres",
	FactoryItemID.RAW_STONE: "res://features/factory_system/factory_items/item_definitions/stone.tres"
}
