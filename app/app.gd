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




func load_world(world_scene: PackedScene):
	if current_world: 
		unload_world()

	#load world
	var instance := world_scene.instantiate()
	var world := instance as GameWorld
	if world == null:
		return
	current_world = world

	world.compose_world_context()

	#configure and bind the world
	#configure: fixed, one-time world dependency
	#bind: replaceable dependency that pair with an unbind 
	world.configure_dependencies()
	ui_root.bind_world(world.context)

	#_ready only triggers after a node enters the tree.
	world_loaded.emit(world)

	add_child(world)

	return


## Unbinds persistent UI before removing the active world.
func unload_world() -> void:
	if current_world == null:
		return

	#unbind world
	ui_root.unbind_world()
	
	#unload world
	current_world.shutdown()
	remove_child(current_world)
	current_world.queue_free()
	world_unloaded.emit(current_world)
