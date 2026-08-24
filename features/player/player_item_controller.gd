extends Node3D
class_name PlayerItemController

var held_factory_item: FactoryItem = null
@export var grid_controller: Node 

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			if held_factory_item == null: return

			var drop_cell = grid_controller.cell_at_mouse_position()
			var drop_position = grid_controller.position_at_cell(drop_cell)
			drop_position.y = 0.167
			
			if global_position.distance_to(drop_position) > Player.PICKUP_DISTANCE: return
			
			held_factory_item.drop_at(drop_position)
			held_factory_item.position = drop_position
			held_factory_item = null
			get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if held_factory_item:
		held_factory_item.position = global_position
