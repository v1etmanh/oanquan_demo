class_name FloatingScore
extends Label
# FloatingScore — spawned at a cell position, floats up and fades out

const FLOAT_SPEED  := 80.0
const FADE_TIME    := 0.8

var _elapsed: float = 0.0

func _init_popup(label_text: String, color: Color, world_pos: Vector2) -> void:
	self.text = label_text
	add_theme_color_override("font_color", color)
	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	add_theme_constant_override("shadow_offset_x", 2)
	add_theme_constant_override("shadow_offset_y", 2)
	add_theme_font_size_override("font_size", 28)
	self.position = world_pos + Vector2(-24, -20)
	self.z_index  = 100

func _process(delta: float) -> void:
	_elapsed   += delta
	var t       := _elapsed / FADE_TIME
	position.y -= FLOAT_SPEED * delta
	modulate.a  = 1.0 - t
	if _elapsed >= FADE_TIME:
		queue_free()
