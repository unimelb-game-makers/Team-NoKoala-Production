class_name FactoryItem
extends Processable
@export var definition : FactoryItemDefinition

@onready var sprite: Sprite3D = $Sprite3D

func _ready() -> void:
	sprite.texture = definition.texture
