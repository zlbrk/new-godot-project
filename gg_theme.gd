class_name GGTheme
extends RefCounted

# -----------------------------------------------------------------------------
# Application scale
# -----------------------------------------------------------------------------
const BASE_UI_SCALE: float = 1.0
const BASE_APPLICATION_FONT_SIZE: int = 16

# -----------------------------------------------------------------------------
# Viewport metrics at ui_scale == 1.0
# -----------------------------------------------------------------------------
const BASE_FONT: Font = preload("res://FiraCode-Medium.ttf")
const BASE_LINE_WIDTH: float = 1.5
const BASE_POINT_RADIUS: float = 4.0
const BASE_AXIS_WIDTH: float = 2.0
const BASE_AXIS_LENGTH: float = 25.0
const BASE_LABEL_OFFSET: Vector2 = Vector2(8.0, -8.0)
const BASE_POINT_LABEL_FONT_SIZE: int = 14
const BASE_LINE_LABEL_FONT_SIZE: int = 14
const BASE_LOOP_LABEL_FONT_SIZE: int = 14
const BASE_SURFACE_LABEL_FONT_SIZE: int = 15
const BASE_AXIS_LABEL_FONT_SIZE: int = 14

# -----------------------------------------------------------------------------
# Colors and label harmony
# -----------------------------------------------------------------------------
# Axes: Red and Green-Yellow
const X_AXIS_COLOR: Color = Color(1.0, 0.25, 0.25)
const Y_AXIS_COLOR: Color = Color(0.65, 0.95, 0.2)

# 0D Points: Warm Ivory
const POINT_COLOR: Color = Color(0.96, 0.88, 0.74)
const POINT_LABEL_COLOR: Color = Color(1.0, 0.93, 0.82)

# 1D Lines: Deep Sky Blue
const LINE_COLOR: Color = Color(0.0, 0.75, 1.0)
const LINE_LABEL_COLOR: Color = Color(0.55, 0.88, 1.0)

# 1D Closed Loops: Warm Amber
const LOOP_LABEL_COLOR: Color = Color(1.0, 0.75, 0.25)

# 2D Surfaces: Translucent Mint/Emerald & Matching Vivid Mint Label
const SURFACE_FILL_COLOR: Color = Color(0.0, 0.85, 0.55, 0.16)
const SURFACE_LABEL_COLOR: Color = Color(0.25, 0.98, 0.70)

# -----------------------------------------------------------------------------
# Scale helpers
# -----------------------------------------------------------------------------
static func ui_scale() -> float:
	var screen_id: int = DisplayServer.window_get_current_screen()
	var screen_scale: float = DisplayServer.screen_get_scale(screen_id)
	return maxf(BASE_UI_SCALE, screen_scale)


static func scaled_pixels(base_value: float) -> float:
	return base_value * ui_scale()


static func scaled_font_size(base_size: int) -> int:
	return maxi(1, roundi(float(base_size) * ui_scale()))


static func line_width() -> float:
	return scaled_pixels(BASE_LINE_WIDTH)


static func point_radius() -> float:
	return scaled_pixels(BASE_POINT_RADIUS)


static func axis_width() -> float:
	return scaled_pixels(BASE_AXIS_WIDTH)


static func axis_length() -> float:
	return scaled_pixels(BASE_AXIS_LENGTH)


static func label_offset() -> Vector2:
	return BASE_LABEL_OFFSET * ui_scale()


static func point_label_font_size() -> int:
	return scaled_font_size(BASE_POINT_LABEL_FONT_SIZE)


static func line_label_font_size() -> int:
	return scaled_font_size(BASE_LINE_LABEL_FONT_SIZE)


static func loop_label_font_size() -> int:
	return scaled_font_size(BASE_LOOP_LABEL_FONT_SIZE)


static func surface_label_font_size() -> int:
	return scaled_font_size(BASE_SURFACE_LABEL_FONT_SIZE)


static func axis_label_font_size() -> int:
	return scaled_font_size(BASE_AXIS_LABEL_FONT_SIZE)


# -----------------------------------------------------------------------------
# Godot Control theme
# -----------------------------------------------------------------------------
static func create_application_theme() -> Theme:
	var application_theme: Theme = Theme.new()
	application_theme.default_font = BASE_FONT
	application_theme.default_font_size = scaled_font_size(BASE_APPLICATION_FONT_SIZE)
	return application_theme


static func apply_application_theme(root: Control) -> void:
	root.theme = create_application_theme()