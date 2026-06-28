extends Control
class_name GGViewport



const POINT_RADIUS: float = 4.0 # just points size
const POINT_COLOR: Color = Color.ANTIQUE_WHITE # just points color

const WORLD_SCALE: float = 1000.0 # reasonable scale for models defined in mm
const SCREEN_ORIGIN: Vector2 = Vector2(80, 80) # reasonable draft testing origin

const LABEL_OFFSET: Vector2 = Vector2(8.0, -8.0)
const LABEL_FONT_SIZE: int = 14
const LABEL_COLOR: Color = Color.WHITE

var model: GGModel = null # define document model referense
var font: Font = get_theme_default_font()

const AXIS_LABEL_FONT_SCALE: float = 1.0 # base theme font scaling for axis labels
const POINT_LABEL_FONT_SCALE: float = 0.85 # font scaling for point labels

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
	var screen_x: float = origin.x + point.x * WORLD_SCALE
	var screen_y: float = origin.y - point.y * WORLD_SCALE
	return Vector2(screen_x, screen_y)

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
			font,
			screen_position + LABEL_OFFSET,
			str(point.id),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			get_scaled_font_size(POINT_LABEL_FONT_SCALE),
			LABEL_COLOR
		)


func draw_axes() -> void:
	var axis_length: float = 100.0
	var origin: Vector2 = get_screen_origin()
	draw_line(
		origin + Vector2(0.0, 0.0),
		origin + Vector2(axis_length, 0.0),
		Color.RED,
		2.0
	)
	draw_string(
	font,
	origin + Vector2(20.0, 50.0),
	"X",
	HORIZONTAL_ALIGNMENT_CENTER,
	-1.0,
	get_scaled_font_size(AXIS_LABEL_FONT_SCALE),
	LABEL_COLOR
	)
	draw_line(
		origin + Vector2(0.0, -axis_length),
		origin + Vector2(0.0, 0.0),
		Color.GREEN_YELLOW,
		2.0
	)
	draw_string(
		font,
		origin + Vector2(-0.0, -50.0),
		"Y",
		HORIZONTAL_ALIGNMENT_RIGHT,
		-10.0,
		get_scaled_font_size(AXIS_LABEL_FONT_SCALE),
		LABEL_COLOR
	)

func get_screen_origin() -> Vector2:
	return size * 0.5
