extends Control
class_name GGViewport

const TEST_POINT_POSITION: Vector2 = Vector2(100, 100)
const TEST_POINT_RADIUS: float = 4.0
const TEST_POINT_COLOR: Color = Color.ANTIQUE_WHITE

func _draw() -> void:
	draw_circle(TEST_POINT_POSITION, TEST_POINT_RADIUS, TEST_POINT_COLOR)
