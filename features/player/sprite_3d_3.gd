extends Sprite3D

func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("e"):
		visible = !visible
