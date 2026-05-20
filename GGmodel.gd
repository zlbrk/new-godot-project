class_name GGModel
extends RefCounted

var document_name: String = "Untitled.geo"
var units: String = "mm"
var is_dirty: bool = false

func reset() -> void:
	document_name = "Untitled.geo"
	units = "mm"
	is_dirty = false
