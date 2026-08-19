extends Node3D

const PLAYER = preload("res://features/player/kaguya.tscn")
@onready var test_grid = $TestGrid

func _ready() -> void:
	var player = PLAYER.instantiate()
	player.connect("ready", player_loaded.bind(player))
	test_grid.add_child(player)
	
	player.position.y = 0.5

func player_loaded(player: Player) -> void:
	test_grid.get_node("GridInteractionController").camera = player.camera
