class_name UiKit
## Small factory helpers so all UI components look the same.

const PANEL_COLOR := Color(0.12, 0.15, 0.21, 0.97)


static func label(font_size: int, text := "") -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", font_size)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


static func icon(texture: Texture2D, min_size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.custom_minimum_size = min_size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


static func button(text: String, callback: Callable, font_size := 24, height := 64.0) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = Vector2(0, height)
	result.add_theme_font_size_override("font_size", font_size)
	result.pressed.connect(callback)
	return result


## Turns `panel` into an opaque, centered dialog and returns the column to fill.
static func setup_dialog(panel: PanelContainer, margin := 20, min_width := 0.0) -> VBoxContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var box := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		box.add_theme_constant_override("margin_" + side, margin)
	panel.add_child(box)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(min_width, 0)
	column.add_theme_constant_override("separation", 14)
	box.add_child(column)
	return column
