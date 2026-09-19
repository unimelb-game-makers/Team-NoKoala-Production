class_name RecipeWorkRequirement
extends Resource

@export var port_id: StringName = &"default"
@export var work_type: WorkType = WorkType.CRAFTING


enum WorkType {
	CRAFTING,
	RITUAL,
	CONSTRUCTION,
}
