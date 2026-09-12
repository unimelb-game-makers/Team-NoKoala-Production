extends Sprite3D


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("blink"):
		var tween = create_tween()
		tween.tween_property(self, "position", Vector3(0, -0.05, -2), 0.05)
