extends MeshInstance3D

@export var player: Node3D
@export var fade_distance: float = 3.0
var is_faded: bool = false

func _ready() -> void:
	var original_mat = get_active_material(0)
	original_mat = original_mat.duplicate()
	set_surface_override_material(0, original_mat)

func set_faded(fade: bool):
	is_faded = fade

func _process(delta: float) -> void:
	var mat = get_surface_override_material(0)
	if player:
		if mat:
			mat.set_shader_parameter("character_position", player.global_position)
			mat.set_shader_parameter("is_faded", is_faded)
