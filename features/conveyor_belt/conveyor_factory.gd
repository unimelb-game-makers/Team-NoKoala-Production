class_name ConveyorFactory

const DEMO_CONVEYOR_SCENE = preload("res://features/conveyor_belt/demo_conveyor_belt.tscn")

const conveyor_scenes: Dictionary = {
}


static func create_conveyor_belt() -> ConveyorBelt:
	var conveyor := DEMO_CONVEYOR_SCENE.instantiate() as ConveyorBelt
	assert(conveyor.block != null, "ConveyorBelt requires a Block component")
	return conveyor
