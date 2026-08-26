extends Control
class_name GGViewport

# -----------------------------------------------------------------------------
# Model
# -----------------------------------------------------------------------------

var model: GGModel = null

# -----------------------------------------------------------------------------
# World and viewport configuration
# -----------------------------------------------------------------------------

const WORLD_SCALE: float = 1000.0

const ZOOM_STEP: float = 1.25
const MIN_ZOOM: float = 0.05
const MAX_ZOOM: float = 100.0

var zoom: float = 1.0
var pan_offset: Vector2 = Vector2.ZERO

# -----------------------------------------------------------------------------
# Public API
# -----------------------------------------------------------------------------

func set_model(new_model: GGModel) -> void:
	model = new_model
	queue_redraw()


func reset_view() -> void:
	zoom = 1.0
	pan_offset = Vector2.ZERO
	queue_redraw()


func set_zoom(new_zoom: float) -> void:
	zoom = clampf(new_zoom, MIN_ZOOM, MAX_ZOOM)
	queue_redraw()


func zoom_in() -> void:
	set_zoom(zoom * ZOOM_STEP)


func zoom_out() -> void:
	set_zoom(zoom / ZOOM_STEP)


func zoom_in_at(screen_position: Vector2) -> void:
	zoom_at(screen_position, ZOOM_STEP)


func zoom_out_at(screen_position: Vector2) -> void:
	zoom_at(screen_position, 1.0 / ZOOM_STEP)


func zoom_at(screen_position: Vector2, factor: float) -> void:
	if factor <= 0.0:
		return

	var zoom_before: float = zoom
	var origin_before: Vector2 = get_screen_origin()

	zoom = clampf(zoom * factor, MIN_ZOOM, MAX_ZOOM)

	var actual_factor: float = zoom / zoom_before
	var cursor_offset: Vector2 = screen_position - origin_before

	pan_offset += cursor_offset * (1.0 - actual_factor)
	queue_redraw()


func pan_by(delta: Vector2) -> void:
	pan_offset += delta
	queue_redraw()


func set_pan_offset(new_offset: Vector2) -> void:
	pan_offset = new_offset
	queue_redraw()


func get_world_scale() -> float:
	return WORLD_SCALE * zoom


func get_screen_origin() -> Vector2:
	return size * 0.5 + pan_offset


func world_to_screen(point: GGPoint2D) -> Vector2:
	var origin: Vector2 = get_screen_origin()

	return Vector2(
		origin.x + point.x * get_world_scale(),
		origin.y - point.y * get_world_scale()
	)

# -----------------------------------------------------------------------------
# Rendering helpers
# -----------------------------------------------------------------------------

func get_viewport_font() -> Font:
	return get_theme_default_font()


func draw_axes() -> void:
	var origin: Vector2 = get_screen_origin()
	var axis_length: float = GGTheme.axis_length()
	var axis_width: float = GGTheme.axis_width()
	var font: Font = get_viewport_font()

	draw_line(
		origin,
		origin + Vector2.RIGHT * axis_length,
		GGTheme.X_AXIS_COLOR,
		axis_width
	)

	draw_string(
		font,
		origin + Vector2(axis_length * 0.25, axis_length * 0.625),
		"X",
		HORIZONTAL_ALIGNMENT_CENTER,
		-1.0,
		GGTheme.axis_label_font_size(),
		GGTheme.LABEL_COLOR
	)

	draw_line(
		origin + Vector2.UP * axis_length,
		origin,
		GGTheme.Y_AXIS_COLOR,
		axis_width
	)

	draw_string(
		font,
		origin + Vector2(-axis_length * 0.5, -axis_length * 0.125),
		"Y",
		HORIZONTAL_ALIGNMENT_RIGHT,
		-10.0,
		GGTheme.axis_label_font_size(),
		GGTheme.LABEL_COLOR
	)


func draw_points() -> void:
	if model == null:
		return

	var font: Font = get_viewport_font()
	var point_label_size: int = GGTheme.point_label_font_size()

	for point: GGPoint2D in model.points:
		var screen_position: Vector2 = world_to_screen(point)

		draw_circle(
			screen_position,
			GGTheme.point_radius(),
			GGTheme.POINT_COLOR
		)

		draw_string(
			font,
			screen_position + GGTheme.label_offset(),
			str(point.id),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			point_label_size,
			GGTheme.LABEL_COLOR
		)

# -----------------------------------------------------------------------------
# Godot callbacks
# -----------------------------------------------------------------------------

func _draw() -> void:
	draw_axes()
	draw_points()