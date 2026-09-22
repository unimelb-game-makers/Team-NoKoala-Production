@tool
class_name CameraController
extends SpringArm3D

@export var drag_sensitivity: float = 0.05
var dragging: bool = false
var isFreeEdit: bool = false

# for camera rotation
@onready var camera: Camera3D = $Camera3D
@export var fade_objects: Array[StaticBody3D] = []
@export var follow_offsets: Vector3
@export var max_distance: float = 4.0
@export var min_distance: float = 1.0
@export var player: Player

var mouse_sensitivity := 0.005
var current_offset: Vector3 = Vector3.ZERO

# for object fade
var fade_object : StaticBody3D = null
var ray_cast : RayCast3D


func configure(p_player: Player) -> void:
	player = p_player


func _ready() -> void:
	if spring_length > max_distance:
		spring_length = max_distance
	elif spring_length < min_distance:
		spring_length = min_distance

	current_offset = follow_offsets


func _process(_delta: float) -> void:
	if player:
		global_position = player.global_position + current_offset


func _physics_process(_delta: float) -> void:
	set_faded_objects()


func set_faded_objects():
	if player == null:
		return
	if not ray_cast:
		create_ray_cast()
	# ray cast from camera to player
	ray_cast.global_position = self.global_position
	ray_cast.target_position = ray_cast.to_local(player.global_position)
	ray_cast.force_raycast_update()
	
	var new_faded_object: StaticBody3D = null
	
	if ray_cast.is_colliding():
		var collider = ray_cast.get_collider()
		if collider == player:
			new_faded_object = null
		# if it hits the object in fade_objects and not the player -> player must be behind this object
		elif collider in fade_objects:
			new_faded_object = collider
	
	# update the fade: unfade the old one and fade the new one (if it exists)
	if new_faded_object != fade_object:
		if fade_object:
			var mesh_instance = get_fade_target(fade_object)
			if mesh_instance:
				mesh_instance.set_faded(false)
		if new_faded_object:
			var mesh_instance = get_fade_target(new_faded_object)
			if mesh_instance:
				mesh_instance.set_faded(true)
		fade_object = new_faded_object


func get_fade_target(body: StaticBody3D) -> Node:
	for child in body.get_children():
		if child is MeshInstance3D and child.has_method("set_faded"):
			return child
	return null


func create_ray_cast():
	ray_cast = RayCast3D.new()
	ray_cast.collide_with_areas = true
	ray_cast.collide_with_bodies = true
	ray_cast.collision_mask = (1 << 2) | (1 << 0)  # layers 3 and 1
	add_child(ray_cast)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_length = clamp(spring_length - 0.5, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_length = clamp(spring_length + 0.5, min_distance, max_distance)
	elif event is InputEventMouseMotion and dragging:
		if isFreeEdit:
			var delta = Vector3(event.relative.x, 0, event.relative.y) * drag_sensitivity
			position -= delta
		else:
			var amount: float = event.relative.x * mouse_sensitivity
			current_offset = current_offset.rotated(Vector3.UP, amount)
			rotate_y(amount)
