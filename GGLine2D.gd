class_name GGLine2D
extends RefCounted

var id: int
var start_point_id: int
var end_point_id: int


func _init(new_id: int, p_start: int, p_end: int) -> void:
	id = new_id
	start_point_id = p_start
	end_point_id = p_end