class_name GGModel
extends RefCounted


var document_name: String = "Untitled.ggb"
var units: String = "mm"
var is_dirty: bool = false
var points: Array[GGPoint2D] = []
var next_point_id: int = 1

func reset() -> void:
	document_name = "Untitled.ggb"
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
	is_dirty = true

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
	document_name = new_name + ".ggb"
	is_dirty = true

# Функция для выгрузки документа в бинарный файл
func save_document() -> bool:
	var save_path: String = "user://" + document_name
	var file: FileAccess = FileAccess.open(
		save_path,
		FileAccess.WRITE
	)

	if file == null:
		return false

	file.store_var(document_name)
	file.store_var(units)
	file.store_var(next_point_id)
	file.store_var(points.size())

	for point: GGPoint2D in points:
		file.store_var(point.id)
		file.store_var(point.x)
		file.store_var(point.y)

	file.close()

	is_dirty = false

	return true

# Функция для загрузки документа из бинарного файла
func load_document(doc_name: String) -> bool:
	var load_path: String = "user://" + doc_name + ".ggb"

	if not FileAccess.file_exists(load_path):
		return false

	var file: FileAccess = FileAccess.open(
		load_path,
		FileAccess.READ
	)

	if file == null:
		return false

	var loaded_document_name: String = String(file.get_var())
	var loaded_units: String = String(file.get_var())
	var loaded_next_point_id: int = int(file.get_var())
	var point_count: int = int(file.get_var())

	var loaded_points: Array[GGPoint2D] = []

	for _index: int in range(point_count):
		var point_id: int = int(file.get_var())
		var x: float = float(file.get_var())
		var y: float = float(file.get_var())

		var point: GGPoint2D = GGPoint2D.new(
			point_id,
			x,
			y
		)

		loaded_points.append(point)

	file.close()

	document_name = loaded_document_name
	units = loaded_units
	next_point_id = loaded_next_point_id
	points = loaded_points
	is_dirty = false

	return true