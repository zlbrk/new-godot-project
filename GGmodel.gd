class_name GGModel
extends RefCounted


var document_name: String = "Untitled.geo"
var units: String = "mm"
var is_dirty: bool = false
var points: Array[GGPoint2D] = []
var next_point_id: int = 1

func reset() -> void:
	document_name = "Untitled.geo"
	units = "mm"
	is_dirty = false
	points.clear()
	next_point_id = 1

func add_point(x: float, y: float) -> GGPoint2D:
	var point: GGPoint2D = GGPoint2D.new(next_point_id, x, y)
	points.append(point)
	next_point_id += 1
	is_dirty = true
	return point

func clear_points() -> void:
	points.clear()
	is_dirty = false

func move_point(point_id: int, x: float, y: float) -> bool:
	for point: GGPoint2D in points:
		if point.id == point_id:
			point.x = x
			point.y = y
			is_dirty = true
			return true
	return false

func remove_point(point_id: int) -> bool:
	for index: int in range(points.size()):
		var point: GGPoint2D = points[index]
		if point.id == point_id:
			points.remove_at(index)
			is_dirty = true
			return true
	return false

func rename_document(new_name: String) -> void:
	document_name = new_name
	is_dirty = true
