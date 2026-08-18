class_name BlockFactory

const DEMO_BLOCK_SCENE = preload("res://features/blocks/demo_block.tscn")

static func create_block() -> Block:
	var block := DEMO_BLOCK_SCENE.instantiate() as Block
	return block
