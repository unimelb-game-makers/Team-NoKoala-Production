extends CharacterBody3D

var target_move_direction: Vector3 = Vector3(0,0,0)
var move_direction: Vector3 = Vector3(0,0,0) 
var player_speed: float = 125.0
var target_y_velocity: float = 0.0
const GRAVITY_SCALE: float = 1.0
const JUMP_STRENGTH: float = 2.075
const MAX_GROUND_PLAYER_SPEED = 325.0
const MAX_AIR_PLAYER_SPEED = 375.0
const MIN_PLAYER_SPEED = 125.0

func _input(event: InputEvent) -> void:
	if event.is_echo(): return
	
	if event.is_action_pressed("jump"):
		jump()

func _physics_process(delta: float) -> void:
	target_move_direction = Vector3(Input.get_axis("move_left","move_right"),0.0,Input.get_axis("move_up","move_down"))
	
	if is_on_floor():
		move_direction = lerp(move_direction, target_move_direction, 0.03)
	else:
		move_direction = lerp(move_direction, target_move_direction, 0.01)
	
	# Resets speed upon hitting obstacle
	if Vector2(get_real_velocity().x, get_real_velocity().z).length() < 0.15:
		player_speed = lerpf(player_speed, MIN_PLAYER_SPEED/2, 1.0)
	
	elif target_move_direction.length() != 0.0:
		if is_on_floor():
			player_speed = lerpf(player_speed, MAX_GROUND_PLAYER_SPEED, 0.05)
		else:
			player_speed = lerpf(player_speed, MAX_AIR_PLAYER_SPEED, 0.003)
	else:
		if is_on_floor():
			player_speed = lerpf(player_speed, MIN_PLAYER_SPEED, 0.2)
		else:
			player_speed = lerpf(player_speed, MIN_PLAYER_SPEED, 0.01)
	
	# Normalising move_direction if it would be longer than 1
	if move_direction.length() > 1.0: move_direction /= move_direction.length()
	
	velocity = move_direction * player_speed * delta
	velocity.y = target_y_velocity
	
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
	if is_on_floor():
		target_y_velocity = JUMP_STRENGTH
