class_name TextureSlider
extends HSlider

## HSlider that draws its track and thumb from textures scaled to fixed sizes,
## so the look doesn't depend on the textures' pixel resolution (built-in
## slider icons and 9-slice styles are drawn at texture size).
## The built-in grabber icons are replaced with an invisible texture of
## `thumb_size`, so the slider's own input and value mapping match what is drawn.

@export var track_texture: Texture2D
@export var thumb_texture: Texture2D
## Drawn instead of `thumb_texture` while the slider has focus.
@export var thumb_selected_texture: Texture2D
@export var track_height := 35.0
@export var thumb_size := Vector2(46, 46)


func _ready() -> void:
	var image := Image.create_empty(int(thumb_size.x), int(thumb_size.y), false, Image.FORMAT_RGBA8)
	var invisible_grabber := ImageTexture.create_from_image(image)
	for icon in ["grabber", "grabber_highlight", "grabber_disabled"]:
		add_theme_icon_override(icon, invisible_grabber)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func _draw() -> void:
	var mid := size.y * 0.5
	if track_texture != null:
		draw_texture_rect(track_texture, Rect2(0.0, mid - track_height * 0.5, size.x, track_height), false)

	var thumb := thumb_selected_texture if has_focus() and thumb_selected_texture != null else thumb_texture
	if thumb == null:
		return
	var span := maxf(max_value - min_value, 0.0001)
	var ratio := clampf((value - min_value) / span, 0.0, 1.0)
	var x := ratio * (size.x - thumb_size.x)
	draw_texture_rect(thumb, Rect2(Vector2(x, mid - thumb_size.y * 0.5), thumb_size), false)
