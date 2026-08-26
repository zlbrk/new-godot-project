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

const BASE_POINT_RADIUS: float = 4.0
const BASE_AXIS_WIDTH: float = 2.0
const BASE_AXIS_LENGTH: float = 50.0

const BASE_LABEL_OFFSET: Vector2 = Vector2(8.0, -8.0)
const BASE_AXIS_LABEL_FONT_SIZE: int = 14
const BASE_POINT_LABEL_FONT_SIZE: int = 16

# -----------------------------------------------------------------------------
# Colors
# -----------------------------------------------------------------------------

const POINT_COLOR: Color = Color.ANTIQUE_WHITE
const LABEL_COLOR: Color = Color.WHITE
const X_AXIS_COLOR: Color = Color.RED
const Y_AXIS_COLOR: Color = Color.GREEN_YELLOW

# -----------------------------------------------------------------------------
# Scale
# -----------------------------------------------------------------------------

static func ui_scale() -> float:
	var screen_id: int = DisplayServer.window_get_current_screen()
	var screen_scale: float = DisplayServer.screen_get_scale(screen_id)

	return maxf(BASE_UI_SCALE, screen_scale)


static func scaled_pixels(base_value: float) -> float:
	return base_value * ui_scale()


static func scaled_font_size(base_size: int) -> int:
	return maxi(1, roundi(float(base_size) * ui_scale()))

# -----------------------------------------------------------------------------
# Godot Control theme
# -----------------------------------------------------------------------------

static func create_application_theme() -> Theme:
	var application_theme: Theme = Theme.new()
	application_theme.default_font_size = scaled_font_size(
		BASE_APPLICATION_FONT_SIZE
	)

	return application_theme


static func apply_application_theme(root: Control) -> void:
	root.theme = create_application_theme()

# -----------------------------------------------------------------------------
# Viewport metrics
# -----------------------------------------------------------------------------

static func point_radius() -> float:
	return scaled_pixels(BASE_POINT_RADIUS)


static func axis_width() -> float:
	return scaled_pixels(BASE_AXIS_WIDTH)


static func axis_length() -> float:
	return scaled_pixels(BASE_AXIS_LENGTH)


static func label_offset() -> Vector2:
	return BASE_LABEL_OFFSET * ui_scale()


static func axis_label_font_size() -> int:
	return scaled_font_size(BASE_AXIS_LABEL_FONT_SIZE)


static func point_label_font_size() -> int:
	return scaled_font_size(BASE_POINT_LABEL_FONT_SIZE)