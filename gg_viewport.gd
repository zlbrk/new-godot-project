extends Control
class_name GGViewport

var model: GGModel = null # define document model referense

# -----------------------------------------------------------------------------
# Rendering constants
# -----------------------------------------------------------------------------
const WORLD_SCALE: float = 1000.0 # reasonable scale for models defined in mm
const AXIS_LENGTH: float = 50.0

const POINT_RADIUS: float = 4.0 # just points size
const POINT_COLOR: Color = Color.ANTIQUE_WHITE # just points color
const LABEL_OFFSET: Vector2 = Vector2(8.0, -8.0)
const LABEL_COLOR: Color = Color.WHITE

const AXIS_LABEL_FONT_SCALE: float = 0.85 # base theme font scaling for axis labels
const POINT_LABEL_FONT_SCALE: float = 1.0 # font scaling for point labels

# -----------------------------------------------------------------------------
# Viewport state
# -----------------------------------------------------------------------------
const ZOOM_STEP: float = 1.25
const MIN_ZOOM: float = 0.05
const MAX_ZOOM: float = 100.0

var zoom: float = 1.0
var pan_offset: Vector2 = Vector2.ZERO

# -----------------------------------------------------------------------------
# User functions
# -----------------------------------------------------------------------------


func zoom_at(screen_position: Vector2, factor: float) -> void:
	if factor <= 0.0:
		return

	var origin_before: Vector2 = get_screen_origin()
	var zoom_before: float = zoom

	set_zoom(zoom * factor)

	var actual_factor: float = zoom / zoom_before
	var cursor_offset: Vector2 = screen_position - origin_before

	pan_offset += cursor_offset * (1.0 - actual_factor)


func zoom_in_at(screen_position: Vector2) -> void:
	zoom_at(screen_position, ZOOM_STEP)


func zoom_out_at(screen_position: Vector2) -> void:
	zoom_at(screen_position, 1.0 / ZOOM_STEP)


func reset_view() -> void:
	set_zoom(1.0)
	set_pan_offset(Vector2.ZERO)


func pan_by (delta: Vector2) -> void:
	pan_offset += delta


func set_pan_offset (new_offset: Vector2) -> void:
	pan_offset = new_offset


func set_zoom(new_zoom: float) -> void:
	zoom = clampf(new_zoom, MIN_ZOOM, MAX_ZOOM)


func zoom_in() -> void:
	set_zoom(zoom * ZOOM_STEP)


func zoom_out() -> void:
	set_zoom(zoom / ZOOM_STEP)


func get_world_scale() -> float:
	return WORLD_SCALE * zoom


func get_screen_origin() -> Vector2:
	return size * 0.5 + pan_offset


func get_viewport_font() -> Font:
	return get_theme_default_font()


func get_base_font_size() -> int:
	return get_theme_default_font_size()


func get_scaled_font_size(font_scale: float) -> int:
	var base_size: int = get_base_font_size()
	var scaled_size: float = float(base_size) * font_scale
	return int(round(scaled_size))


func set_model(new_model: GGModel) -> void:
	model = new_model
	queue_redraw()


func world_to_screen(point: GGPoint2D) -> Vector2:
	var origin: Vector2 = get_screen_origin()
	var screen_x: float = origin.x + point.x * get_world_scale()
	var screen_y: float = origin.y - point.y * get_world_scale()
	return Vector2(screen_x, screen_y)


func draw_axes() -> void:
	
	var origin: Vector2 = get_screen_origin()
	draw_line(
		origin + Vector2(0.0, 0.0),
		origin + Vector2(AXIS_LENGTH, 0.0),
		Color.RED,
		2.0
	)
	draw_string(
	get_viewport_font(),
	origin + Vector2(AXIS_LENGTH/16, +AXIS_LENGTH/4+AXIS_LENGTH/16)*2,
	"X",
	HORIZONTAL_ALIGNMENT_CENTER,
	-1.0,
	get_scaled_font_size(AXIS_LABEL_FONT_SCALE),
	LABEL_COLOR
	)
	draw_line(
		origin + Vector2(0.0, -AXIS_LENGTH),
		origin + Vector2(0.0, 0.0),
		Color.GREEN_YELLOW,
		2.0
	)
	draw_string(
		get_viewport_font(),
		origin + Vector2(-AXIS_LENGTH/4, -AXIS_LENGTH/16)*2,
		"Y",
		HORIZONTAL_ALIGNMENT_RIGHT,
		-10.0,
		get_scaled_font_size(AXIS_LABEL_FONT_SCALE),
		LABEL_COLOR
	)


func _draw() -> void:
	if model == null:
		return
	draw_axes()

	for point: GGPoint2D in model.points:
		var screen_position: Vector2 = world_to_screen(point)
		draw_circle(
			screen_position,
			POINT_RADIUS,
			POINT_COLOR
		)
		draw_string(
			get_viewport_font(),
			screen_position + LABEL_OFFSET,
			str(point.id),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			get_scaled_font_size(POINT_LABEL_FONT_SCALE),
			LABEL_COLOR
		)


