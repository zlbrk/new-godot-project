extends Control
class_name GGViewport

const TEST_POINT_POSITION: Vector2 = Vector2(100, 100) # used for testing purposes only
const POINT_RADIUS: float = 4.0 # just points size
const POINT_COLOR: Color = Color.ANTIQUE_WHITE # just points color
const WORLD_SCALE: float = 1000.0 # reasonable scale for models defined in mm
const SCREEN_ORIGIN: Vector2 = Vector2(80, 80) # reasonable draft testing origin

var model: GGModel = null # define document model referense

func set_model(new_model: GGModel) -> void:
	model = new_model
	queue_redraw()

func world_to_screen(point: GGPoint2D) -> Vector2:
	var screen_x: float = SCREEN_ORIGIN.x + point.x * WORLD_SCALE
	var screen_y: float = SCREEN_ORIGIN.y + point.y * WORLD_SCALE
	return Vector2(screen_x, screen_y)

func _draw() -> void:
	if model == null:
		return
	# draw_circle(TEST_POINT_POSITION, POINT_RADIUS, POINT_COLOR)
	for point: GGPoint2D in model.points:
		var screen_position: Vector2 = world_to_screen(point)
		draw_circle(screen_position, POINT_RADIUS, POINT_COLOR)
