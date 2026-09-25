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


func _draw_arrow(
	from: Vector2,
	to: Vector2,
	color: Color,
	line_width: float,
	arrow_size: float
) -> void:
	var delta: Vector2 = to - from
	var length: float = delta.length()
	if length < arrow_size or delta.is_zero_approx():
		return
	var dir: Vector2 = delta / length
	var normal: Vector2 = Vector2(-dir.y, dir.x)

	var arrow_base: Vector2 = to - dir * arrow_size
	var half_width: float = arrow_size * 0.4
	var left_wing: Vector2 = arrow_base + normal * half_width
	var right_wing: Vector2 = arrow_base - normal * half_width

	draw_line(from, arrow_base, color, line_width, true)
	var triangle_points: PackedVector2Array = PackedVector2Array([to, left_wing, right_wing])
	draw_colored_polygon(triangle_points, color)


func draw_axes() -> void:
	var font: Font = get_viewport_font()
	var font_size: int = GGTheme.axis_label_font_size()
	var axis_len: float = GGTheme.axis_length()
	var axis_w: float = GGTheme.axis_width()
	var arrow_size: float = axis_w * 4.0
	var gap: float = float(font_size) * 0.4

	var origin: Vector2 = world_to_screen(GGPoint2D.new(0, 0.0, 0.0))
	var x_end: Vector2 = origin + Vector2(axis_len, 0.0)
	var y_end: Vector2 = origin + Vector2(0.0, -axis_len)

	_draw_arrow(origin, x_end, GGTheme.X_AXIS_COLOR, axis_w, arrow_size)
	_draw_arrow(origin, y_end, GGTheme.Y_AXIS_COLOR, axis_w, arrow_size)

	var x_text_size: Vector2 = font.get_string_size("X", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var x_pos: Vector2 = Vector2(
		x_end.x + gap,
		x_end.y + x_text_size.y * 0.35
	)
	draw_string(font, x_pos, "X", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, GGTheme.X_AXIS_COLOR)

	var y_text_size: Vector2 = font.get_string_size("Y", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var y_pos: Vector2 = Vector2(
		y_end.x - y_text_size.x * 0.5,
		y_end.y - gap
	)
	draw_string(font, y_pos, "Y", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, GGTheme.Y_AXIS_COLOR)


func draw_surfaces() -> void:
	if model == null:
		return
	var font: Font = get_viewport_font()
	var font_size: int = GGTheme.surface_label_font_size()
	var fill_color: Color = GGTheme.SURFACE_FILL_COLOR
	var label_color: Color = GGTheme.SURFACE_LABEL_COLOR

	for surface: GGSurface2D in model.surfaces:
		if surface.loop_ids.is_empty():
			continue

		var outer_loop: GGLoop2D = model.get_loop_by_id(surface.loop_ids[0])
		if outer_loop == null:
			continue

		var outer_pts: Array[GGPoint2D] = model.get_loop_points(outer_loop)
		if outer_pts.size() < 3:
			continue

		var outer_poly: PackedVector2Array = PackedVector2Array()
		for pt: GGPoint2D in outer_pts:
			outer_poly.append(world_to_screen(pt))

		var current_polys: Array[PackedVector2Array] = [outer_poly]

		for i: int in range(1, surface.loop_ids.size()):
			var hole_loop: GGLoop2D = model.get_loop_by_id(surface.loop_ids[i])
			if hole_loop == null:
				continue
			var hole_pts: Array[GGPoint2D] = model.get_loop_points(hole_loop)
			if hole_pts.size() < 3:
				continue

			var hole_poly: PackedVector2Array = PackedVector2Array()
			for pt: GGPoint2D in hole_pts:
				hole_poly.append(world_to_screen(pt))

			var next_polys: Array[PackedVector2Array] = []
			for poly: PackedVector2Array in current_polys:
				var clipped: Array[PackedVector2Array] = Geometry2D.clip_polygons(poly, hole_poly)
				next_polys.append_array(clipped)
			current_polys = next_polys

		for poly: PackedVector2Array in current_polys:
			if poly.size() >= 3:
				draw_colored_polygon(poly, fill_color)

		var centroid_world: Vector2 = model.get_loop_centroid(outer_loop)
		var centroid_screen: Vector2 = world_to_screen(GGPoint2D.new(0, centroid_world.x, centroid_world.y))
		var text: String = "S%d" % surface.id
		var text_sz: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var text_pos: Vector2 = centroid_screen + Vector2(-text_sz.x * 0.5, -text_sz.y * 0.6)
		draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_color)


func draw_loops() -> void:
	if model == null:
		return
	var font: Font = get_viewport_font()
	var font_size: int = GGTheme.loop_label_font_size()
	var label_color: Color = GGTheme.LOOP_LABEL_COLOR

	for loop: GGLoop2D in model.loops:
		var centroid_world: Vector2 = model.get_loop_centroid(loop)
		var centroid_screen: Vector2 = world_to_screen(GGPoint2D.new(0, centroid_world.x, centroid_world.y))
		var text: String = "L%d" % loop.id
		var text_sz: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var text_pos: Vector2 = centroid_screen + Vector2(-text_sz.x * 0.5, text_sz.y * 0.8)
		draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_color)


func draw_lines() -> void:
	if model == null:
		return
	for line: GGLine2D in model.lines:
		var p_start: GGPoint2D = model.get_point_by_id(line.start_point_id)
		var p_end: GGPoint2D = model.get_point_by_id(line.end_point_id)
		if p_start == null or p_end == null:
			continue
		var start_screen: Vector2 = world_to_screen(p_start)
		var end_screen: Vector2 = world_to_screen(p_end)
		draw_line(start_screen, end_screen, GGTheme.LINE_COLOR, GGTheme.line_width(), true)


func draw_line_labels() -> void:
	if model == null:
		return
	var font: Font = get_viewport_font()
	var font_size: int = GGTheme.line_label_font_size()
	var label_color: Color = GGTheme.LINE_LABEL_COLOR

	for line: GGLine2D in model.lines:
		var p_start: GGPoint2D = model.get_point_by_id(line.start_point_id)
		var p_end: GGPoint2D = model.get_point_by_id(line.end_point_id)
		if p_start == null or p_end == null:
			continue

		var start_screen: Vector2 = world_to_screen(p_start)
		var end_screen: Vector2 = world_to_screen(p_end)
		var delta: Vector2 = end_screen - start_screen
		if delta.is_zero_approx():
			continue

		var mid_point: Vector2 = (start_screen + end_screen) * 0.5
		var normal: Vector2 = -Vector2(-delta.y, delta.x).normalized()
		var offset_dist: float = float(font_size) * 0.75
		var label_center: Vector2 = mid_point + normal * offset_dist

		var text: String = str(line.id)
		var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var text_pos: Vector2 = label_center - Vector2(text_size.x * 0.5, -text_size.y * 0.3)
		draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_color)


func draw_points() -> void:
	if model == null:
		return
	var font: Font = get_viewport_font()
	var point_label_size: int = GGTheme.point_label_font_size()
	var offset: Vector2 = GGTheme.label_offset()
	var label_color: Color = GGTheme.POINT_LABEL_COLOR

	for point: GGPoint2D in model.points:
		var screen_position: Vector2 = world_to_screen(point)
		draw_circle(
			screen_position, GGTheme.point_radius(), GGTheme.POINT_COLOR
		)
		var text: String = str(point.id)
		draw_string(
			font, screen_position + offset, text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, point_label_size, label_color
		)


# -----------------------------------------------------------------------------
# Godot callbacks
# -----------------------------------------------------------------------------
func _draw() -> void:
	draw_axes()
	draw_surfaces()
	draw_loops()
	draw_lines()
	draw_line_labels()
	draw_points()