class_name SFXManager
extends Node


@export var whistle_sfx: AudioStreamWAV
@export var sfx_player: AudioStreamPlayer

var _player: Player


func configure(player: Player) -> void:
	_player = player
	if _player != null and not _player.interaction_controller.whistled.is_connected(_on_whistled):
		_player.interaction_controller.whistled.connect(_on_whistled)


func _play(stream: AudioStream) -> void:
	if stream == null or sfx_player == null:
		return
	sfx_player.stream = stream
	sfx_player.play()


func _on_whistled() -> void:
	_play(whistle_sfx)
