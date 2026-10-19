extends CharacterBody3D
class_name Player

@export var can_jump: bool = false
@export var interaction_controller: PlayerInteractionController
@export var work_controller: PlayerMachineWorkController
@export var inventory_owner: InventoryOwner
@export var animation_tree: AnimationTree
@export var spring_arm: CameraController

var _gate: FeatureGate

const GRAVITY_SCALE: float = 1.0
const JUMP_STRENGTH: float = 2.075

var target_move_direction: Vector3 = Vector3(0,0,0)
var move_direction: Vector3 = Vector3(0,0,0) 
@export var max_move_speed: float = 1.5
@onready var _max_move_speed_squared := max_move_speed * max_move_speed
var rotation_speed: float = 10.0
var target_y_velocity: float = 0.0
var is_working: bool = false
var is_currying: bool = false
var is_sprinting: bool = false


func configure(
	p_spring_arm: CameraController,
	placement: MachinePlacementController,
	jobs: JobBoard,
	grid: Grid,
	factory: FactoryManager,
	hotbar: Hotbar,
	machine_ui: MachineUI,
	item_stack_list_panel: ItemStackListPanel,
	gate: FeatureGate = null,
) -> void:
	spring_arm = p_spring_arm
	_gate = gate
	interaction_controller.configure(
		p_spring_arm,
		placement,
		jobs,
		machine_ui,
		grid,
		factory,
		item_stack_list_panel,
		gate,
	)
	work_controller.configure(grid, factory, gate)
	inventory_owner.configure(hotbar)


func _ready() -> void:
	var inventory := inventory_owner.inventory
	inventory.slot_changed.connect(_on_inventory_changed.unbind(1))
	inventory.selected_index_changed.connect(_on_inventory_changed.unbind(2))
	_on_inventory_changed()


func _input(event: InputEvent) -> void:
	if event.is_echo(): return
	
	if event.is_action_pressed("jump"):
		jump()
	
	if event.is_action_pressed("sprint"):
		is_sprinting = not is_sprinting


func _process(_delta: float) -> void:
	if is_on_floor():
		var xz_velocity := velocity
		xz_velocity.y = 0
		var forward := xz_velocity.length_squared() / _max_move_speed_squared
		_set_move_scalar(forward)
	else:
		_set_move_scalar(0)


func _physics_process(delta: float) -> void:
	# movement relative to spring arm rotation
	var input_vec := Vector2.ZERO
	if FeatureGate.check(_gate, GameFeature.Id.MOVE):
		input_vec = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var cam_basis: Basis
	if spring_arm != null:
		cam_basis = spring_arm.global_transform.basis
	else:
		cam_basis = Basis()

	var cam_right := cam_basis.x
	cam_right.y = 0.0
	var cam_back := cam_basis.z
	cam_back.y = 0.0
	target_move_direction = cam_right.normalized() * input_vec.x + cam_back.normalized() * input_vec.y
	if not is_currying and is_sprinting:
		target_move_direction = target_move_direction.normalized() * 2
	
	if is_on_floor():
		move_direction = lerp(move_direction, target_move_direction, 1 - pow(0.02, delta))
	else:
		move_direction = lerp(move_direction, target_move_direction, 1 - pow(0.4, delta))
	
	velocity = move_direction * max_move_speed
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
	if is_on_floor() and can_jump and FeatureGate.check(_gate, GameFeature.Id.JUMP):
		target_y_velocity = JUMP_STRENGTH


func _on_inventory_changed() -> void:
	is_currying = inventory_owner.inventory.hand_slot != null

func _set_move_scalar(scalar: float) -> void:
	animation_tree.set(&"parameters/Normal/blend_position", scalar)
	animation_tree.set(&"parameters/Currying/BlendSpace1D/blend_position", scalar)
