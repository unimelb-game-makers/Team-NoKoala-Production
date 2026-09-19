class_name RecipeWorkRequirement
extends Resource

@export var port_id: StringName = &"default"
@export var work_type: WorkType.Value = WorkType.Value.CRAFTING


enum WorkType {
	CRAFTING,
	RITUAL,
	CONSTRUCTION,
}
