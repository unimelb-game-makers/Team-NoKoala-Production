class_name FactoryItem
extends Processable
@export var definition : FactoryItemDefinition

@onready var sprite: Sprite3D = $Sprite3D
@onready var pickup_area: Area3D = $Sprite3D/Area3D

var _pickup_collision_layer: int
var _pickup_input_ray_pickable: bool

func _ready() -> void:
	sprite.texture = definition.texture
	_pickup_collision_layer = pickup_area.collision_layer
	_pickup_input_ray_pickable = pickup_area.input_ray_pickable


func set_in_process_hidden(is_hidden: bool) -> void:
	sprite.visible = not is_hidden
	pickup_area.collision_layer = 0 if is_hidden else _pickup_collision_layer
	pickup_area.input_ray_pickable = (
		false if is_hidden else _pickup_input_ray_pickable
	)
