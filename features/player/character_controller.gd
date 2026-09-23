extends CharacterBody3D
class_name Player

@export var can_jump: bool = true
@export var interaction_controller: PlayerInteractionController
@export var work_controller: PlayerMachineWorkController
@export var animation_tree: AnimationTree
@export var spring_arm: CameraController

const GRAVITY_SCALE: float = 1.0
const JUMP_STRENGTH: float = 2.075
const MAX_GROUND_PLAYER_SPEED = 4.0
const MAX_AIR_PLAYER_SPEED = 5.0
const MIN_PLAYER_SPEED = 1.5

var target_move_direction: Vector3 = Vector3(0,0,0)
var move_direction: Vector3 = Vector3(0,0,0) 
var player_speed: float = 1.5
var rotation_speed: float = 10.0
var target_y_velocity: float = 0.0


func configure(
	p_spring_arm: CameraController,
	placement: MachinePlacementController,
	jobs: JobBoard,
	grid: Grid,
	factory: FactoryManager,
) -> void:
	spring_arm = p_spring_arm
	interaction_controller.configure(p_spring_arm, placement, jobs)
	work_controller.configure(grid, factory)

func _input(event: InputEvent) -> void:
	if event.is_echo(): return
	
	if event.is_action_pressed("jump"):
		jump()


func _process(_delta: float) -> void:
	const MIN_PLAYER_SPEED_SQUARED = MIN_PLAYER_SPEED * MIN_PLAYER_SPEED
	if is_on_floor():
		var xz_velocity := velocity
		xz_velocity.y = 0
		var forward := xz_velocity.length_squared() / MIN_PLAYER_SPEED_SQUARED
		animation_tree.set(&"parameters/Normal/blend_position", forward)
	else:
		animation_tree.set(&"parameters/Normal/blend_position", 0)


func _physics_process(delta: float) -> void:
	# movement relative to spring arm rotation
	var input_vec = Vector3(Input.get_axis("move_left","move_right"),0.0,Input.get_axis("move_up","move_down"))
	var cam_basis
	if spring_arm != null:
		cam_basis = spring_arm.global_transform.basis
	else:
		cam_basis = Basis()
	target_move_direction = (cam_basis.x * input_vec.x + cam_basis.z * input_vec.z)
	
	if is_on_floor():
		move_direction = lerp(move_direction, target_move_direction, 1 - pow(0.25, delta))
	else:
		move_direction = lerp(move_direction, target_move_direction, 1 - pow(0.4, delta))
	
	# Resets speed upon hitting obstacle
	if Vector2(get_real_velocity().x, get_real_velocity().z).length() < 0.01:
		player_speed = MIN_PLAYER_SPEED/2
	
	elif target_move_direction.length() != 0.0:
		if is_on_floor():
			player_speed = lerpf(player_speed, MAX_GROUND_PLAYER_SPEED, 1 - pow(0.01, delta))
		else:
			player_speed = lerpf(player_speed, MAX_AIR_PLAYER_SPEED, 1 - pow(0.1, delta))
	else:
		if is_on_floor():
			player_speed = lerpf(player_speed, MIN_PLAYER_SPEED, 1 - pow(0.003, delta))
		else:
			player_speed = lerpf(player_speed, MIN_PLAYER_SPEED, 1 - pow(0.1, delta))
	
	# Normalising move_direction if it would be longer than 1
	if move_direction.length() > 1.0: move_direction /= move_direction.length()
	
	velocity = move_direction * player_speed
	velocity.y = target_y_velocity

	if move_direction.length_squared() > 0.001:
		var target_angle = atan2(move_direction.x, move_direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, rotation_speed * delta)
	
	# Enact Gravity
	if not is_on_floor():
		target_y_velocity = velocity.y + (get_gravity().y * GRAVITY_SCALE * delta)
	
	move_and_slide()
	
	# Check if player is holding jump (Should jump again)
	if Input.is_action_pressed("jump"): 
		jump()
	elif is_on_floor():
		target_y_velocity = 0.0

func jump() -> void:
	if is_on_floor() and can_jump:
		target_y_velocity = JUMP_STRENGTH
