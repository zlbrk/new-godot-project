class_name GGModel
extends RefCounted

var document_name: String = "Untitled.ggb"
var units: String = "mm"
var is_dirty: bool = false

var points: Array[GGPoint2D] = []
var next_point_id: int = 1

var lines: Array[GGLine2D] = []
var next_line_id: int = 1

var loops: Array[GGLoop2D] = []
var next_loop_id: int = 1

var surfaces: Array[GGSurface2D] = []
var next_surface_id: int = 1


func reset() -> void:
	document_name = "Untitled.ggb"
	units = "mm"
	is_dirty = false
	points.clear()
	next_point_id = 1
	lines.clear()
	next_line_id = 1
	loops.clear()
	next_loop_id = 1
	surfaces.clear()
	next_surface_id = 1


# -----------------------------------------------------------------------------
# Points management
# -----------------------------------------------------------------------------
func get_point_by_id(point_id: int) -> GGPoint2D:
	for point: GGPoint2D in points:
		if point.id == point_id:
			return point
	return null


func add_point(x: float, y: float) -> GGPoint2D:
	var point: GGPoint2D = GGPoint2D.new(next_point_id, x, y)
	points.append(point)
	next_point_id += 1
	is_dirty = true
	return point


func move_point(point_id: int, x: float, y: float) -> bool:
	var point: GGPoint2D = get_point_by_id(point_id)
	if point != null:
		point.x = x
		point.y = y
		is_dirty = true
		return true
	return false


func remove_point(point_id: int) -> bool:
	if is_point_used(point_id):
		return false
	for index: int in range(points.size()):
		if points[index].id == point_id:
			points.remove_at(index)
			is_dirty = true
			return true
	return false


func clear_points() -> bool:
	if not lines.is_empty():
		return false
	points.clear()
	next_point_id = 1
	is_dirty = true
	return true


# -----------------------------------------------------------------------------
# Lines management
# -----------------------------------------------------------------------------
func get_line_by_id(line_id: int) -> GGLine2D:
	for line: GGLine2D in lines:
		if line.id == line_id:
			return line
	return null


func add_line(start_id: int, end_id: int) -> GGLine2D:
	if start_id == end_id:
		return null
	if get_point_by_id(start_id) == null or get_point_by_id(end_id) == null:
		return null
	var line: GGLine2D = GGLine2D.new(next_line_id, start_id, end_id)
	lines.append(line)
	next_line_id += 1
	is_dirty = true
	return line


func remove_line(line_id: int) -> bool:
	if is_line_used(line_id):
		return false
	for index: int in range(lines.size()):
		if lines[index].id == line_id:
			lines.remove_at(index)
			is_dirty = true
			return true
	return false


func clear_lines() -> bool:
	if not loops.is_empty():
		return false
	lines.clear()
	next_line_id = 1
	is_dirty = true
	return true


# -----------------------------------------------------------------------------
# Loops management
# -----------------------------------------------------------------------------
func get_loop_by_id(loop_id: int) -> GGLoop2D:
	for loop: GGLoop2D in loops:
		if loop.id == loop_id:
			return loop
	return null


func validate_loop_candidate(signed_line_ids: Array[int]) -> String:
	if signed_line_ids.size() < 3:
		return "Loop must contain at least 3 line segments."
	var first_start_point_id: int = -1
	var current_end_point_id: int = -1

	for i: int in range(signed_line_ids.size()):
		var signed_id: int = signed_line_ids[i]
		if signed_id == 0:
			return "Line ID cannot be 0."
		var line: GGLine2D = get_line_by_id(absi(signed_id))
		if line == null:
			return "Line %d does not exist." % [absi(signed_id)]

		var seg_start: int = line.start_point_id if signed_id > 0 else line.end_point_id
		var seg_end: int = line.end_point_id if signed_id > 0 else line.start_point_id

		if i == 0:
			first_start_point_id = seg_start
		else:
			if seg_start != current_end_point_id:
				return "Discontinuity at segment %d: Line %d starts at Point %d, but previous segment ended at Point %d." % [
					i + 1, signed_id, seg_start, current_end_point_id
				]
		current_end_point_id = seg_end

	if current_end_point_id != first_start_point_id:
		return "Loop is not closed: last segment ends at Point %d, expected start Point %d." % [
			current_end_point_id, first_start_point_id
		]
	return ""


func add_loop(signed_line_ids: Array[int]) -> GGLoop2D:
	var validation_error: String = validate_loop_candidate(signed_line_ids)
	if not validation_error.is_empty():
		return null
	var loop: GGLoop2D = GGLoop2D.new(next_loop_id, signed_line_ids)
	loops.append(loop)
	next_loop_id += 1
	is_dirty = true
	return loop


func remove_loop(loop_id: int) -> bool:
	if is_loop_used(loop_id):
		return false
	for index: int in range(loops.size()):
		if loops[index].id == loop_id:
			loops.remove_at(index)
			is_dirty = true
			return true
	return false


func clear_loops() -> bool:
	if not surfaces.is_empty():
		return false
	loops.clear()
	next_loop_id = 1
	is_dirty = true
	return true


func get_loop_points(loop: GGLoop2D) -> Array[GGPoint2D]:
	var loop_pts: Array[GGPoint2D] = []
	for signed_id: int in loop.signed_line_ids:
		var line: GGLine2D = get_line_by_id(absi(signed_id))
		if line == null:
			return []
		var pt_id: int = line.start_point_id if signed_id > 0 else line.end_point_id
		var pt: GGPoint2D = get_point_by_id(pt_id)
		if pt == null:
			return []
		loop_pts.append(pt)
	return loop_pts


func get_loop_centroid(loop: GGLoop2D) -> Vector2:
	var pts: Array[GGPoint2D] = get_loop_points(loop)
	var count: int = pts.size()
	if count == 0:
		return Vector2.ZERO
	var area_twice: float = 0.0
	var cx: float = 0.0
	var cy: float = 0.0
	for i: int in range(count):
		var p1: GGPoint2D = pts[i]
		var p2: GGPoint2D = pts[(i + 1) % count]
		var cross: float = p1.x * p2.y - p2.x * p1.y
		area_twice += cross
		cx += (p1.x + p2.x) * cross
		cy += (p1.y + p2.y) * cross
	if absf(area_twice) < 1e-6:
		var sum_v: Vector2 = Vector2.ZERO
		for p: GGPoint2D in pts:
			sum_v += Vector2(p.x, p.y)
		return sum_v / float(count)
	return Vector2(cx / (3.0 * area_twice), cy / (3.0 * area_twice))


# -----------------------------------------------------------------------------
# Surfaces management (CRUD)
# -----------------------------------------------------------------------------
func get_surface_by_id(surface_id: int) -> GGSurface2D:
	for surface: GGSurface2D in surfaces:
		if surface.id == surface_id:
			return surface
	return null


func validate_surface_candidate(loop_ids: Array[int]) -> String:
	if loop_ids.is_empty():
		return "Surface must contain at least one boundary loop."
	var unique_loops: Dictionary = {}
	for lid: int in loop_ids:
		if lid <= 0:
			return "Loop ID must be a positive integer."
		if get_loop_by_id(lid) == null:
			return "Loop %d does not exist." % [lid]
		if unique_loops.has(lid):
			return "Duplicate loop reference %d in surface." % [lid]
		unique_loops[lid] = true
	return ""


func add_surface(loop_ids: Array[int]) -> GGSurface2D:
	var err: String = validate_surface_candidate(loop_ids)
	if not err.is_empty():
		return null
	var surface: GGSurface2D = GGSurface2D.new(next_surface_id, loop_ids)
	surfaces.append(surface)
	next_surface_id += 1
	is_dirty = true
	return surface


func update_surface(surface_id: int, new_loop_ids: Array[int]) -> String:
	var surface: GGSurface2D = get_surface_by_id(surface_id)
	if surface == null:
		return "Surface %d not found." % [surface_id]
	var err: String = validate_surface_candidate(new_loop_ids)
	if not err.is_empty():
		return err
	surface.loop_ids = new_loop_ids
	is_dirty = true
	return ""


func remove_surface(surface_id: int) -> bool:
	for index: int in range(surfaces.size()):
		if surfaces[index].id == surface_id:
			surfaces.remove_at(index)
			is_dirty = true
			return true
	return false


func clear_surfaces() -> void:
	surfaces.clear()
	next_surface_id = 1
	is_dirty = true


# -----------------------------------------------------------------------------
# Topology inspection and cascade safeguards
# -----------------------------------------------------------------------------
func get_lines_referencing_point(point_id: int) -> Array[int]:
	var referencing: Array[int] = []
	for line: GGLine2D in lines:
		if line.start_point_id == point_id or line.end_point_id == point_id:
			referencing.append(line.id)
	return referencing


func is_point_used(point_id: int) -> bool:
	for line: GGLine2D in lines:
		if line.start_point_id == point_id or line.end_point_id == point_id:
			return true
	return false


func get_loops_referencing_line(line_id: int) -> Array[int]:
	var referencing: Array[int] = []
	for loop: GGLoop2D in loops:
		for signed_id: int in loop.signed_line_ids:
			if absi(signed_id) == line_id:
				referencing.append(loop.id)
				break
	return referencing


func is_line_used(line_id: int) -> bool:
	for loop: GGLoop2D in loops:
		for signed_id: int in loop.signed_line_ids:
			if absi(signed_id) == line_id:
				return true
	return false


func get_surfaces_referencing_loop(loop_id: int) -> Array[int]:
	var referencing: Array[int] = []
	for surface: GGSurface2D in surfaces:
		if loop_id in surface.loop_ids:
			referencing.append(surface.id)
	return referencing


func is_loop_used(loop_id: int) -> bool:
	for surface: GGSurface2D in surfaces:
		if loop_id in surface.loop_ids:
			return true
	return false


func validate_topology() -> Array[String]:
	var errors: Array[String] = []
	for line: GGLine2D in lines:
		if line.start_point_id == line.end_point_id:
			errors.append("Line %d is degenerate (identical endpoints: %d)." % [line.id, line.start_point_id])
		if get_point_by_id(line.start_point_id) == null:
			errors.append("Line %d references missing start Point %d." % [line.id, line.start_point_id])
		if get_point_by_id(line.end_point_id) == null:
			errors.append("Line %d references missing end Point %d." % [line.id, line.end_point_id])

	for loop: GGLoop2D in loops:
		var loop_err: String = validate_loop_candidate(loop.signed_line_ids)
		if not loop_err.is_empty():
			errors.append("Loop %d invalid: %s" % [loop.id, loop_err])

	for surface: GGSurface2D in surfaces:
		var surf_err: String = validate_surface_candidate(surface.loop_ids)
		if not surf_err.is_empty():
			errors.append("Surface %d invalid: %s" % [surface.id, surf_err])
	return errors


func rename_document(new_name: String) -> void:
	document_name = new_name + ".ggb"
	is_dirty = true


# -----------------------------------------------------------------------------
# Gmsh .geo Export
# -----------------------------------------------------------------------------
func export_geo_file(target_filename: String) -> bool:
	var path: String = "user://" + target_filename + ".geo"
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_line("// Generated by GG CAD")
	file.store_line("// Model: " + document_name)
	file.store_line("")
	file.store_line("// Points")
	for point: GGPoint2D in points:
		file.store_line("Point(%d) = {%.6f, %.6f, 0};" % [point.id, point.x, point.y])
	file.store_line("")
	file.store_line("// Lines")
	for line: GGLine2D in lines:
		file.store_line("Line(%d) = {%d, %d};" % [line.id, line.start_point_id, line.end_point_id])
	if not loops.is_empty():
		file.store_line("")
		file.store_line("// Curve Loops")
		for loop: GGLoop2D in loops:
			var formatted_ids: PackedStringArray = PackedStringArray()
			for signed_id: int in loop.signed_line_ids:
				formatted_ids.append(str(signed_id))
			file.store_line("Curve Loop(%d) = {%s};" % [loop.id, ", ".join(formatted_ids)])
	if not surfaces.is_empty():
		file.store_line("")
		file.store_line("// Plane Surfaces")
		for surface: GGSurface2D in surfaces:
			var formatted_lids: PackedStringArray = PackedStringArray()
			for lid: int in surface.loop_ids:
				formatted_lids.append(str(lid))
			file.store_line("Plane Surface(%d) = {%s};" % [surface.id, ", ".join(formatted_lids)])
	file.close()
	return true


# -----------------------------------------------------------------------------
# Persistence (.ggb)
# -----------------------------------------------------------------------------
func save_document() -> bool:
	var save_path: String = "user://" + document_name
	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_var(document_name)
	file.store_var(units)
	file.store_var(next_point_id)
	# Points
	file.store_var(points.size())
	for point: GGPoint2D in points:
		file.store_var(point.id)
		file.store_var(point.x)
		file.store_var(point.y)
	# Lines
	file.store_var(next_line_id)
	file.store_var(lines.size())
	for line: GGLine2D in lines:
		file.store_var(line.id)
		file.store_var(line.start_point_id)
		file.store_var(line.end_point_id)
	# Loops
	file.store_var(next_loop_id)
	file.store_var(loops.size())
	for loop: GGLoop2D in loops:
		file.store_var(loop.id)
		file.store_var(loop.signed_line_ids.size())
		for signed_id: int in loop.signed_line_ids:
			file.store_var(signed_id)
	# Surfaces
	file.store_var(next_surface_id)
	file.store_var(surfaces.size())
	for surface: GGSurface2D in surfaces:
		file.store_var(surface.id)
		file.store_var(surface.loop_ids.size())
		for lid: int in surface.loop_ids:
			file.store_var(lid)
	file.close()
	is_dirty = false
	return true


func load_document(doc_name: String) -> bool:
	var load_path: String = "user://" + doc_name + ".ggb"
	if not FileAccess.file_exists(load_path):
		return false
	var file: FileAccess = FileAccess.open(load_path, FileAccess.READ)
	if file == null:
		return false
	var loaded_document_name: String = String(file.get_var())
	var loaded_units: String = String(file.get_var())
	var loaded_next_point_id: int = int(file.get_var())
	var loaded_points: Array[GGPoint2D] = []
	var point_count_var: Variant = file.get_var()
	if point_count_var == null:
		file.close()
		return false
	var point_count: int = int(point_count_var)
	for _i: int in range(point_count):
		var p_id: int = int(file.get_var())
		var px: float = float(file.get_var())
		var py: float = float(file.get_var())
		loaded_points.append(GGPoint2D.new(p_id, px, py))

	var loaded_next_line_id: int = 1
	var loaded_lines: Array[GGLine2D] = []
	if file.get_position() < file.get_length():
		var next_line_var: Variant = file.get_var()
		if next_line_var != null:
			loaded_next_line_id = int(next_line_var)
		var line_count_var: Variant = file.get_var()
		if line_count_var != null:
			var line_count: int = int(line_count_var)
			for _j: int in range(line_count):
				var l_id: int = int(file.get_var())
				var p_start: int = int(file.get_var())
				var p_end: int = int(file.get_var())
				loaded_lines.append(GGLine2D.new(l_id, p_start, p_end))

	var loaded_next_loop_id: int = 1
	var loaded_loops: Array[GGLoop2D] = []
	if file.get_position() < file.get_length():
		var next_loop_var: Variant = file.get_var()
		if next_loop_var != null:
			loaded_next_loop_id = int(next_loop_var)
		var loop_count_var: Variant = file.get_var()
		if loop_count_var != null:
			var loop_count: int = int(loop_count_var)
			for _k: int in range(loop_count):
				var loop_id: int = int(file.get_var())
				var seg_count: int = int(file.get_var())
				var seg_ids: Array[int] = []
				for _m: int in range(seg_count):
					seg_ids.append(int(file.get_var()))
				loaded_loops.append(GGLoop2D.new(loop_id, seg_ids))

	var loaded_next_surface_id: int = 1
	var loaded_surfaces: Array[GGSurface2D] = []
	if file.get_position() < file.get_length():
		var next_surf_var: Variant = file.get_var()
		if next_surf_var != null:
			loaded_next_surface_id = int(next_surf_var)
		var surf_count_var: Variant = file.get_var()
		if surf_count_var != null:
			var surf_count: int = int(surf_count_var)
			for _n: int in range(surf_count):
				var s_id: int = int(file.get_var())
				var s_loop_count: int = int(file.get_var())
				var s_loop_ids: Array[int] = []
				for _p: int in range(s_loop_count):
					s_loop_ids.append(int(file.get_var()))
				loaded_surfaces.append(GGSurface2D.new(s_id, s_loop_ids))

	file.close()
	document_name = loaded_document_name
	units = loaded_units
	next_point_id = loaded_next_point_id
	next_line_id = loaded_next_line_id
	next_loop_id = loaded_next_loop_id
	next_surface_id = loaded_next_surface_id
	points = loaded_points
	lines = loaded_lines
	loops = loaded_loops
	surfaces = loaded_surfaces
	is_dirty = false
	return true