extends Node3D
class_name PlayerItemManager

var held_processable: Processable = null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			if held_processable == null: return

			var drop_cell = GridInteractionController.grid_controller_instance.cell_at_mouse_position()
			var drop_position = GridInteractionController.grid_controller_instance.position_at_cell(drop_cell)
			drop_position.y = 0.167
			
			if global_position.distance_to(drop_position) > Player.PICKUP_DISTANCE: return
			
			held_processable.drop_at(drop_position)
			held_processable.position = drop_position
			held_processable = null
			get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if held_processable:
		held_processable.position = global_position
