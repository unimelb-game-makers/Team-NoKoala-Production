class_name App
extends Node

#signals useful in the future
signal world_loaded(world: GameWorld)
signal world_unloaded(world: GameWorld)

## world scene are created from the packedscene in runtime: this is to ensure the consistentn dependency injection
@export var initial_world_scene: PackedScene
@export var ui_root: UIRoot

var current_world: GameWorld


func _ready() -> void:
	assert(ui_root != null, "App requires a UIRoot")
	assert(initial_world_scene != null, "App requires a world scene")
	load_world(initial_world_scene)




func load_world(world_scene: PackedScene) -> GameWorld:

	#build world

	var instance := world_scene.instantiate()
	var world := instance as GameWorld
	if world == null:
		instance.free()
		push_error("App can only load scenes rooted by GameWorld")
		return null
	world.compose()

	unload_world()
	#_ready only triggers after a node enters the tree.
	add_child(world)
	current_world = world


	#bind world 
	
	ui_root.bind_world(world.context)
	world_loaded.emit(world)
	return world


## Unbinds persistent UI before removing the active world.
func unload_world() -> void:
	if current_world == null:
		return

	#release the reference first
	var world := current_world
	current_world = null

	#unbind world
	ui_root.unbind_world()
	
	#unload world
	world.shutdown()
	remove_child(world)
	world.queue_free()
	world_unloaded.emit(world)
