class_name ConveyorFactory

const DEMO_CONVEYOR_SCENE = preload("res://features/conveyor_belt/demo_conveyor_belt.tscn")

const conveyor_scenes: Dictionary = {
}


static func create_conveyor_belt() -> Block:
	var block := DEMO_CONVEYOR_SCENE.instantiate() as Block
	block.block_data.type = BlockData.BlockType.CONVEYOR
	return block
