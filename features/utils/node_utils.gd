class_name NodeUtils

static func get_children_by_type(parent: Node, type) -> Array:
	var matched_children: Array = []
	
	for child in parent.get_children():
		if is_instance_of(child, type):
			matched_children.append(child)
			
	return matched_children

static func get_child_by_type(parent: Node, type) -> Node:
	for child in parent.get_children():
		if is_instance_of(child, type):
			return child
	return null
