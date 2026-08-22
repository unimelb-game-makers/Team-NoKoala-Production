@abstract
class_name FactoryDefinition
extends Resource


@export var ports: Array[FactoryPortDefinition] = []

@abstract func accepts_input(
	port_id: StringName, 
	processable_definition: ProcessableDefinition,
) -> bool


func get_port_definition(port_id: StringName) -> FactoryPortDefinition:
	if port_id == &"":
		return null

	for port in ports:
		if port != null and port.port_id == port_id:
			return port
	return null

