class_name FactoryItem
extends Processable
@export var definition : FactoryItemDefinition
@export var player: Node3D

@onready var sprite: Sprite3D = $Sprite3D


func _ready() -> void:
	sprite.texture = definition.texture


func _on_area_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if player.global_position.distance_to(self.global_position) > Player.PICKUP_DISTANCE: return
			if player.item_manager.held_processable != null: return
			
			try_claim(player)
			player.item_manager.held_processable = self
