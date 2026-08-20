extends Sprite3D

@onready var raycast: RayCast3D = $"../RayCast3D"

func _physics_process(_delta: float) -> void:
	if raycast.is_colliding():
		global_position.y = raycast.get_collision_point().y+0.01
		
	var player_dist = abs(global_position.y - get_parent().global_position.y) / 2.0
	scale = Vector3(clampf(2.4 - player_dist * 1.5, 0.6, 1.7), clampf(2.4 - player_dist * 1.5, 0.6, 1.7), 1)
	modulate.a = clampf(1.2 - player_dist, 0.2, 0.45)
