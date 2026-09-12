class_name NodeUtils

## Returns the first child of the given type, or null if none is found.
static func get_child_by_type(parent: Node, type: Variant) -> Node:
	for child in parent.get_children():
		if is_instance_of(child, type):
			return child
	return null


## Returns an array of all children matching the given type.
static func get_children_by_type(parent: Node, type: Variant) -> Array[Node]:
	var children: Array[Node] = []
	for child in parent.get_children():
		if is_instance_of(child, type):
			children.append(child)
	return children
