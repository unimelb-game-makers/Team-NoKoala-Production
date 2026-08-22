@abstract
class_name FactoryMachine
extends Block

@export var definition: FactoryDefinition


func _enter_tree() -> void:
	FactoryManager.register_factory(self)

func _exit_tree() -> void:
	FactoryManager.unregister_factory(self)
