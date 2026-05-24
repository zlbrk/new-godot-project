class_name GGModel
extends RefCounted


var document_name: String = "Untitled.geo"
var units: String = "mm"
var is_dirty: bool = false

var points: Array[GGPoint2D] = []

func reset() -> void:
	document_name = "Untitled.geo"
	units = "mm"
	is_dirty = false
	points.clear()

func add_point(x: float, y: float) -> void:
	points.append(GGPoint2D.new(x, y))
	is_dirty = true


func clear_points() -> void:
	points.clear()
	is_dirty = false
