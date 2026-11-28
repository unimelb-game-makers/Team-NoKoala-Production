class_name SFXManager
extends Node


@export var whistle_sfx: AudioStreamWAV

var _player: Player
var _sfx_player: AudioStreamPlayer

func configure(
	player: Player,
	sfx_player: AudioStreamPlayer,
) -> void:
	_player = player
	_sfx_player = sfx_player
	if _player != null:
		_player.interaction_controller.whistled.connect(_on_whistled)
		
		
func _play(stream: AudioStream) -> void:
	if stream == null:
		return
	_sfx_player.stream = stream
	_sfx_player.play()
	
func _on_whistled() -> void:
	_play(whistle_sfx)
