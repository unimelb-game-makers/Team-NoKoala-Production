class_name GameSettings
extends RefCounted

## Player settings, persisted to user://settings.cfg.
## Call load_settings() once at startup to restore and apply them.

const PATH := "user://settings.cfg"
const MUSIC_BUS := &"Music"

## 0..100
static var music_volume := 100


static func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		music_volume = clampi(int(config.get_value("audio", "music_volume", music_volume)), 0, 100)
	apply_music_volume(music_volume)


static func save_settings() -> void:
	var config := ConfigFile.new()
	config.load(PATH)  # Keep any other sections already in the file.
	config.set_value("audio", "music_volume", music_volume)
	var err := config.save(PATH)
	if err != OK:
		push_warning("Failed to save settings to %s (error %d)" % [PATH, err])


## Sets the Music bus volume without storing it, e.g. to preview a slider.
static func apply_music_volume(volume: int) -> void:
	var bus := AudioServer.get_bus_index(MUSIC_BUS)
	if bus < 0:
		push_warning("Audio bus '%s' not found" % MUSIC_BUS)
		return
	AudioServer.set_bus_mute(bus, volume <= 0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(volume / 100.0))
