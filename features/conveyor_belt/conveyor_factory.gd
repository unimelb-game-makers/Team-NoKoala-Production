class_name ConveyorFactory

const DEMO_CONVEYOR_SCENE = preload("res://features/conveyor_belt/demo_conveyor_belt.tscn")

const conveyor_scenes: Dictionary = {
}


static func create_conveyor_belt(grid: Grid) -> ConveyorBelt:

	var belt := DEMO_CONVEYOR_SCENE.instantiate() as ConveyorBelt
	belt.initialize(grid)
	return belt
