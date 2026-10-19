class_name CutscenePlayer
extends VideoStreamPlayer


func _input(event: InputEvent) -> void:
	if not is_playing() or not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	stop()
	finished.emit()
