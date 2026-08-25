class_name MobVision
extends Area3D

@export var vision_angle_degrees: float = 60.0
@export var vision_range: float = 10.0

func is_in_sight(target: Node3D) -> bool:
	var dist := global_position.distance_to(target.global_position)
	if dist > vision_range:
		return false
		
	var forward := -global_transform.basis.z # Godot 3D looks down -Z by default
	var flat_forward := Vector3(forward.x, 0, forward.z).normalized()
	
	var dir_to_target := (target.global_position - global_position)
	var flat_dir_to_target := Vector3(dir_to_target.x, 0, dir_to_target.z).normalized()
	
	var dot_prod := flat_forward.dot(flat_dir_to_target)
	var angle_to_target := rad_to_deg(acos(dot_prod))
	
	if angle_to_target <= vision_angle_degrees / 2.0:
		return true
		
	return false
