class_name GGLoop2D
extends RefCounted

var id: int
## Знаковые ID линий (например, [1, 2, -3]):
## положительный ID — обход от start_point_id к end_point_id,
## отрицательный ID — обход от end_point_id к start_point_id.
var signed_line_ids: Array[int] = []


func _init(new_id: int, lines: Array[int] = []) -> void:
	id = new_id
	signed_line_ids = lines
