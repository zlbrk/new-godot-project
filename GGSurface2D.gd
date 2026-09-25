class_name GGSurface2D
extends RefCounted

var id: int
## Список ID петель:
## loop_ids[0] — внешний контур (exterior boundary)
## loop_ids[1..N] — внутренние контуры-вырезы (holes / interior boundaries)
var loop_ids: Array[int] = []


func _init(new_id: int, loops: Array[int] = []) -> void:
	id = new_id
	loop_ids = loops