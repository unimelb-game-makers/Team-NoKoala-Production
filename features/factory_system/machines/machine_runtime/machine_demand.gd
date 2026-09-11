class_name MachineDemand
extends RefCounted

var item: FactoryItemDefinition
var cell: Vector3i


func _init(p_item: FactoryItemDefinition, p_cell: Vector3i) -> void:
	item = p_item
	cell = p_cell
