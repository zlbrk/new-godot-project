extends Control

# ========================================================
# Window configuration
# ========================================================
const INITIAL_WIDTH_FRACTION: float = 0.75
const WINDOW_ASPECT_RATIO: float = 1152.0 / 648.0
const MAX_HEIGHT_FRACTION: float = 0.90

# ========================================================
# Gesture configuration
# ========================================================
const PAN_GESTURE_SCALE: float = 1.0
const MAGNIFY_STEP_FACTOR: float = 1.10
const MAGNIFY_INVERSE_STEP_FACTOR: float = 1.0 / MAGNIFY_STEP_FACTOR
const MAGNIFY_GESTURE_TIMEOUT_MSEC: int = 250
const MIN_MAGNIFY_EVENT_FACTOR: float = 0.5
const MAX_MAGNIFY_EVENT_FACTOR: float = 2.0
const MAX_MAGNIFY_STEPS_PER_EVENT: int = 8

# ========================================================
# Application state
# ========================================================
var command_history: Array[String] = []
var console_lines: Array[String] = []
var history_index: int = 0
var model: GGModel
var is_mouse_panning: bool = false
var _magnify_accumulator: float = 1.0
var _last_magnify_event_msec: int = -1

# ========================================================
# Scene references
# ========================================================
@onready var console_output: RichTextLabel = %ConsoleOutput
@onready var command_line: LineEdit = %CommandLine
@onready var status_label: Label = %StatusLabel
@onready var gg_viewport: GGViewport = (
	$RootLayout/MainSplit/ViewportPanel/GGViewport
)

# ========================================================
# Initialization
# ========================================================
func _ready() -> void:
	GGTheme.apply_application_theme(self)
	model = GGModel.new()
	gg_viewport.set_model(model)
	_connect_signals()
	call_deferred("_configure_initial_window")
	_print_display_diagnostics()
	print_line("GG Editor shell initialized.")
	print_line("Type 'help' for available commands.")
	refocus_command_line()


func _connect_signals() -> void:
	command_line.text_submitted.connect(_on_command_submitted)
	command_line.gui_input.connect(_on_command_line_gui_input)
	gg_viewport.gui_input.connect(_on_gg_viewport_gui_input)


# ========================================================
# Window initialization and diagnostics
# ========================================================
func _configure_initial_window() -> void:
	var window: Window = get_window()
	var screen_rect: Rect2i = DisplayServer.screen_get_usable_rect(window.current_screen)
	var target_width: float = screen_rect.size.x * INITIAL_WIDTH_FRACTION
	var target_height: float = target_width / WINDOW_ASPECT_RATIO
	if target_height > screen_rect.size.y * MAX_HEIGHT_FRACTION:
		target_height = screen_rect.size.y * MAX_HEIGHT_FRACTION
		target_width = target_height * WINDOW_ASPECT_RATIO
	window.size = Vector2i(int(target_width), int(target_height))
	window.position = screen_rect.position + (screen_rect.size - window.size) / 2


func _print_display_diagnostics() -> void:
	var window: Window = get_window()
	var screen: int = window.current_screen
	var screen_rect: Rect2i = DisplayServer.screen_get_usable_rect(screen)
	print_line("Screen usable rect: %s" % [str(screen_rect)])
	print_line("Window initial size: %s" % [str(window.size)])


func refocus_command_line() -> void:
	command_line.grab_focus()


func print_line(text: String) -> void:
	console_output.append_text(text + "\n")


func print_list_item(text: String) -> void:
	console_output.append_text("  " + text + "\n")


# ========================================================
# Command line navigation
# ========================================================
func show_previous_command() -> void:
	if command_history.is_empty():
		return
	history_index = clampi(history_index - 1, 0, command_history.size() - 1)
	command_line.text = command_history[history_index]
	command_line.caret_column = command_line.text.length()


func show_next_command() -> void:
	if command_history.is_empty():
		return
	if history_index < command_history.size() - 1:
		history_index += 1
		command_line.text = command_history[history_index]
		command_line.caret_column = command_line.text.length()
	else:
		history_index = command_history.size()
		command_line.text = ""


func _on_command_line_gui_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_UP:
			show_previous_command()
			command_line.accept_event()
		KEY_DOWN:
			show_next_command()
			command_line.accept_event()


# ========================================================
# Viewport input
# ========================================================
func _on_gg_viewport_gui_input(event: InputEvent) -> void:
	if event is InputEventPanGesture:
		_handle_viewport_pan_gesture(event as InputEventPanGesture)
		return
	if event is InputEventMagnifyGesture:
		_handle_viewport_magnify_gesture(event as InputEventMagnifyGesture)
		return
	if event is InputEventMouseButton:
		_handle_viewport_mouse_button(event as InputEventMouseButton)
		return
	if event is InputEventMouseMotion:
		_handle_viewport_mouse_motion(event as InputEventMouseMotion)


func _handle_viewport_pan_gesture(pan_event: InputEventPanGesture) -> void:
	gg_viewport.pan_by(-pan_event.delta * PAN_GESTURE_SCALE)


func _handle_viewport_magnify_gesture(event: InputEventMagnifyGesture) -> void:
	var now_msec: int = Time.get_ticks_msec()
	if _last_magnify_event_msec < 0 or (now_msec - _last_magnify_event_msec) > MAGNIFY_GESTURE_TIMEOUT_MSEC:
		_magnify_accumulator = 1.0
	_last_magnify_event_msec = now_msec

	var factor: float = clampf(event.factor, MIN_MAGNIFY_EVENT_FACTOR, MAX_MAGNIFY_EVENT_FACTOR)
	_magnify_accumulator *= factor

	var steps: int = 0
	while _magnify_accumulator >= MAGNIFY_STEP_FACTOR and steps < MAX_MAGNIFY_STEPS_PER_EVENT:
		gg_viewport.zoom_in_at(event.position)
		_magnify_accumulator *= MAGNIFY_INVERSE_STEP_FACTOR
		steps += 1
	while _magnify_accumulator <= MAGNIFY_INVERSE_STEP_FACTOR and steps < MAX_MAGNIFY_STEPS_PER_EVENT:
		gg_viewport.zoom_out_at(event.position)
		_magnify_accumulator *= MAGNIFY_STEP_FACTOR
		steps += 1



func _handle_viewport_mouse_button(mouse_event: InputEventMouseButton) -> void:
	match mouse_event.button_index:
		MOUSE_BUTTON_MIDDLE:
			is_mouse_panning = mouse_event.pressed
			gg_viewport.accept_event()
		MOUSE_BUTTON_WHEEL_UP:
			if mouse_event.pressed:
				gg_viewport.zoom_in_at(mouse_event.position)
				gg_viewport.accept_event()
		MOUSE_BUTTON_WHEEL_DOWN:
			if mouse_event.pressed:
				gg_viewport.zoom_out_at(mouse_event.position)
				gg_viewport.accept_event()


func _handle_viewport_mouse_motion(motion_event: InputEventMouseMotion) -> void:
	if is_mouse_panning:
		gg_viewport.pan_by(motion_event.relative)
		gg_viewport.accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_F and event.is_command_or_control_pressed():
			_toggle_fullscreen()
			get_viewport().set_input_as_handled()


func _toggle_fullscreen() -> void:
	var current_mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


# ========================================================
# Command loop
# ========================================================
func _on_command_submitted(command_text: String) -> void:
	var trimmed: String = command_text.strip_edges()
	command_line.text = ""
	if trimmed.is_empty():
		return
	command_history.append(trimmed)
	history_index = command_history.size()
	print_line("> " + trimmed)
	var tokens: PackedStringArray = trimmed.split(" ", false)
	execute_command(tokens)


func execute_command(tokens: PackedStringArray) -> void:
	if tokens.is_empty():
		return
	match tokens[0]:
		"help": cmd_help()
		"clear": cmd_clear()
		"about": cmd_about()
		"new": cmd_new(tokens)
		"save": cmd_save_document()
		"load": cmd_load_document(tokens)
		"history": cmd_history()
		"status": cmd_status()
		"rename": cmd_rename(tokens)
		"list_points": cmd_list_points()
		"add_point": cmd_add_point(tokens)
		"move_point": cmd_move_point(tokens)
		"remove_point": cmd_remove_point(tokens)
		"clear_points": cmd_clear_points()
		"add_line": cmd_add_line(tokens)
		"remove_line": cmd_remove_line(tokens)
		"list_lines": cmd_list_lines()
		"clear_lines": cmd_clear_lines()
		"add_loop": cmd_add_loop(tokens)
		"remove_loop": cmd_remove_loop(tokens)
		"list_loops": cmd_list_loops()
		"clear_loops": cmd_clear_loops()
		"add_surface": cmd_add_surface(tokens)
		"update_surface": cmd_update_surface(tokens)
		"remove_surface": cmd_remove_surface(tokens)
		"list_surfaces": cmd_list_surfaces()
		"clear_surfaces": cmd_clear_surfaces()
		"check_topology": cmd_check_topology()
		"export_geo": cmd_export_geo(tokens)
		"zoom_in": cmd_zoom_in()
		"zoom_out": cmd_zoom_out()
		"set_zoom": cmd_set_zoom(tokens)
		"set_pan_offset": cmd_set_pan_offset(tokens)
		"pan_by": cmd_pan_by(tokens)
		"reset_view": cmd_reset_view()
		_: print_line("Unknown command: %s. Type 'help' for commands." % [tokens[0]])


# ========================================================
# Viewport commands
# ========================================================
func cmd_zoom_in() -> void:
	gg_viewport.zoom_in()
	print_list_item("Zoomed in. Current zoom: %.2f" % [gg_viewport.zoom])


func cmd_zoom_out() -> void:
	gg_viewport.zoom_out()
	print_list_item("Zoomed out. Current zoom: %.2f" % [gg_viewport.zoom])


func cmd_set_zoom(tokens: PackedStringArray) -> void:
	if tokens.size() != 2 or not tokens[1].is_valid_float():
		print_list_item("Usage: set_zoom <factor>")
		return
	var new_zoom: float = tokens[1].to_float()
	gg_viewport.set_zoom(new_zoom)
	print_list_item("Zoom set to: %.2f" % [gg_viewport.zoom])


func cmd_set_pan_offset(tokens: PackedStringArray) -> void:
	if tokens.size() != 3 or not tokens[1].is_valid_float() or not tokens[2].is_valid_float():
		print_list_item("Usage: set_pan_offset <x> <y>")
		return
	var ox: float = tokens[1].to_float()
	var oy: float = tokens[2].to_float()
	gg_viewport.set_pan_offset(Vector2(ox, oy))
	print_list_item("Pan offset set to: (%.2f, %.2f)" % [ox, oy])


func cmd_pan_by(tokens: PackedStringArray) -> void:
	if tokens.size() != 3 or not tokens[1].is_valid_float() or not tokens[2].is_valid_float():
		print_list_item("Usage: pan_by <dx> <dy>")
		return
	var dx: float = tokens[1].to_float()
	var dy: float = tokens[2].to_float()
	gg_viewport.pan_by(Vector2(dx, dy))
	print_list_item("Panned by: (%.2f, %.2f)" % [dx, dy])


func cmd_reset_view() -> void:
	gg_viewport.reset_view()
	print_list_item("View reset to origin.")


# ========================================================
# Model commands: Document
# ========================================================
func update_status_label() -> void:
	var dirty_marker: String = "*" if model.is_dirty else ""
	status_label.text = model.document_name + dirty_marker


func cmd_load_document(tokens: PackedStringArray) -> void:
	if tokens.size() != 2:
		print_line("Usage: load <filename> without extension.")
		return

	if model.is_dirty:
		print_line("Current document has unsaved changes. Save it before loading another document.")
		return

	var doc_name: String = tokens[1]

	if not model.load_document(doc_name):
		print_line("Failed to load document %s.ggb." % [doc_name])
		return

	update_status_label()
	gg_viewport.queue_redraw()
	print_line("Document %s loaded successfully." % [model.document_name])

func cmd_save_document() -> void:
	if not model.save_document():
		print_line("Failed to save document %s." % [model.document_name])
		return

	print_line("Document %s saved successfully." % [model.document_name])
	update_status_label()


func cmd_new(tokens: PackedStringArray) -> void:
	if tokens.size() != 2:
		print_line("Usage: new <filename> without extension.")
		return

	var new_name: String = tokens[1]
	if not model.is_valid_document_name(new_name):
		print_line("Invalid document name: %s" % [new_name])
		return

	if model.is_dirty:
		print_line("Current document has unsaved changes. Save it before creating a new document.")
		return

	model.reset()
	if not model.rename_document(new_name):
		print_line("Failed to create document %s.ggb." % [new_name])
		return

	update_status_label()
	gg_viewport.queue_redraw()
	print_line("New document %s created." % [model.document_name])


func cmd_rename(tokens: PackedStringArray) -> void:
	if tokens.size() != 2:
		print_line("Usage: rename <filename> without extension.")
		return

	var new_name: String = tokens[1]
	if not model.rename_document(new_name):
		print_line("Invalid document name: %s" % [new_name])
		return

	update_status_label()
	print_line("Document renamed to %s." % [model.document_name])


# ========================================================
# Model commands: Points
# ========================================================
func cmd_add_point(tokens: PackedStringArray) -> void:
	if tokens.size() != 3:
		print_list_item("Usage: add_point <x> <y>")
		return
	if not tokens[1].is_valid_float():
		print_line("Invalid X coordinate.")
		return
	if not tokens[2].is_valid_float():
		print_line("Invalid Y coordinate.")
		return
	var px: float = tokens[1].to_float()
	var py: float = tokens[2].to_float()
	var point: GGPoint2D = model.add_point(px, py)
	update_status_label()
	print_list_item("Point %d added." % [point.id])
	gg_viewport.queue_redraw()


func cmd_move_point(tokens: PackedStringArray) -> void:
	if tokens.size() != 4:
		print_list_item("Usage: move_point <ID> <x> <y>")
		return
	if not tokens[1].is_valid_int():
		print_list_item("Error: point ID must be an integer")
		return
	if not (tokens[2].is_valid_float() and tokens[3].is_valid_float()):
		print_list_item("Error: coordinates must be valid floats")
		return
	var point_id: int = tokens[1].to_int()
	var x: float = tokens[2].to_float()
	var y: float = tokens[3].to_float()
	if not model.move_point(point_id, x, y):
		print_list_item("Error: point ID not found")
		return
	print_line("Point %d moved to (%.3f, %.3f)." % [point_id, x, y])
	update_status_label()
	gg_viewport.queue_redraw()


func cmd_remove_point(tokens: PackedStringArray) -> void:
	if tokens.size() != 2:
		print_line("Usage: remove_point <ID>")
		return
	if not tokens[1].is_valid_int():
		print_line("Error: point ID must be an integer.")
		return
	var point_id: int = tokens[1].to_int()
	if model.get_point_by_id(point_id) == null:
		print_list_item("Error: point ID not found.")
		return
	var dependent_lines: Array[int] = model.get_lines_referencing_point(point_id)
	if not dependent_lines.is_empty():
		var ids_formatted: PackedStringArray = PackedStringArray()
		for line_id: int in dependent_lines:
			ids_formatted.append(str(line_id))
		var lines_str: String = ", ".join(ids_formatted)
		print_list_item("Error: cannot remove Point %d. It is used by Line(s): %s." % [point_id, lines_str])
		return
	if model.remove_point(point_id):
		print_line("Point %d removed." % [point_id])
		update_status_label()
		gg_viewport.queue_redraw()
	else:
		print_list_item("Error: failed to remove Point %d." % [point_id])


func cmd_clear_points() -> void:
	if not model.clear_points():
		print_list_item("Error: cannot clear points while lines exist. Remove lines first.")
		return
	print_list_item("Points cleared.")
	update_status_label()
	gg_viewport.queue_redraw()


func cmd_list_points() -> void:
	if model.points.is_empty():
		print_list_item("No points.")
		return
	for i: int in range(model.points.size()):
		var point: GGPoint2D = model.points[i]
		print_list_item("%d: (%.3f, %.3f)" % [point.id, point.x, point.y])


# ========================================================
# Model commands: Lines
# ========================================================
func cmd_add_line(tokens: PackedStringArray) -> void:
	if tokens.size() != 3:
		print_list_item("Usage: add_line <start_point_id> <end_point_id>")
		return
	if not tokens[1].is_valid_int() or not tokens[2].is_valid_int():
		print_list_item("Error: point IDs must be integers.")
		return
	var start_id: int = tokens[1].to_int()
	var end_id: int = tokens[2].to_int()
	if start_id == end_id:
		print_list_item("Error: start and end points cannot be identical.")
		return
	if model.get_point_by_id(start_id) == null:
		print_list_item("Error: start Point %d does not exist." % [start_id])
		return
	if model.get_point_by_id(end_id) == null:
		print_list_item("Error: end Point %d does not exist." % [end_id])
		return
	var line: GGLine2D = model.add_line(start_id, end_id)
	if line == null:
		print_list_item("Error: failed to create line.")
		return
	update_status_label()
	gg_viewport.queue_redraw()
	print_list_item("Line %d added (Point %d -> Point %d)." % [line.id, start_id, end_id])


func cmd_remove_line(tokens: PackedStringArray) -> void:
	if tokens.size() != 2 or not tokens[1].is_valid_int():
		print_list_item("Usage: remove_line <line_id>")
		return
	var line_id: int = tokens[1].to_int()
	var dependent_loops: Array[int] = model.get_loops_referencing_line(line_id)
	if not dependent_loops.is_empty():
		var ids_formatted: PackedStringArray = PackedStringArray()
		for loop_id: int in dependent_loops:
			ids_formatted.append(str(loop_id))
		print_list_item("Error: cannot remove Line %d. It is used by Loop(s): %s." % [
			line_id, ", ".join(ids_formatted)
		])
		return
	if not model.remove_line(line_id):
		print_list_item("Error: Line ID %d not found." % [line_id])
		return
	update_status_label()
	gg_viewport.queue_redraw()
	print_list_item("Line %d removed." % [line_id])


func cmd_list_lines() -> void:
	if model.lines.is_empty():
		print_list_item("No lines.")
		return
	for line: GGLine2D in model.lines:
		print_list_item("Line %d: Point %d -> Point %d" % [line.id, line.start_point_id, line.end_point_id])


func cmd_clear_lines() -> void:
	if not model.clear_lines():
		print_list_item("Error: cannot clear lines while loops exist. Remove loops first.")
		return
	update_status_label()
	gg_viewport.queue_redraw()
	print_list_item("Lines cleared.")


# ========================================================
# Model commands: Loops
# ========================================================
func cmd_add_loop(tokens: PackedStringArray) -> void:
	if tokens.size() < 4:
		print_list_item("Usage: add_loop <signed_line_id1> <signed_line_id2> <signed_line_id3> ...")
		return

	var signed_ids: Array[int] = []
	for i: int in range(1, tokens.size()):
		if not tokens[i].is_valid_int():
			print_list_item("Error: segment token '%s' is not a valid integer ID." % [tokens[i]])
			return
		var sid: int = tokens[i].to_int()
		if sid == 0:
			print_list_item("Error: line ID cannot be 0.")
			return
		signed_ids.append(sid)

	var validation_err: String = model.validate_loop_candidate(signed_ids)
	if not validation_err.is_empty():
		print_list_item("Error: " + validation_err)
		return

	var loop: GGLoop2D = model.add_loop(signed_ids)
	if loop == null:
		print_list_item("Error: failed to create loop.")
		return

	update_status_label()
	gg_viewport.queue_redraw()

	var ids_str: PackedStringArray = PackedStringArray()
	for sid: int in loop.signed_line_ids:
		ids_str.append(str(sid))
	print_list_item("Loop %d added: {%s}." % [loop.id, ", ".join(ids_str)])


func cmd_remove_loop(tokens: PackedStringArray) -> void:
	if tokens.size() != 2 or not tokens[1].is_valid_int():
		print_list_item("Usage: remove_loop <loop_id>")
		return
	var loop_id: int = tokens[1].to_int()
	var dependent_surfaces: Array[int] = model.get_surfaces_referencing_loop(loop_id)
	if not dependent_surfaces.is_empty():
		var ids_formatted: PackedStringArray = PackedStringArray()
		for sid: int in dependent_surfaces:
			ids_formatted.append(str(sid))
		print_list_item("Error: cannot remove Loop %d. It is used by Surface(s): %s." % [
			loop_id, ", ".join(ids_formatted)
		])
		return
	if not model.remove_loop(loop_id):
		print_list_item("Error: Loop ID %d not found." % [loop_id])
		return
	update_status_label()
	gg_viewport.queue_redraw()
	print_list_item("Loop %d removed." % [loop_id])


func cmd_list_loops() -> void:
	if model.loops.is_empty():
		print_list_item("No loops.")
		return
	for loop: GGLoop2D in model.loops:
		var line_tokens: PackedStringArray = PackedStringArray()
		for sid: int in loop.signed_line_ids:
			line_tokens.append(str(sid))
		var pts: Array[GGPoint2D] = model.get_loop_points(loop)
		var pt_tokens: PackedStringArray = PackedStringArray()
		for p: GGPoint2D in pts:
			pt_tokens.append(str(p.id))
		if not pts.is_empty():
			pt_tokens.append(str(pts[0].id))
		print_list_item("Loop %d: lines {%s} -> points [%s]" % [
			loop.id, ", ".join(line_tokens), " -> ".join(pt_tokens)
		])


func cmd_clear_loops() -> void:
	if not model.clear_loops():
		print_list_item("Error: cannot clear loops while surfaces exist. Remove surfaces first.")
		return
	update_status_label()
	gg_viewport.queue_redraw()
	print_list_item("Loops cleared.")


# ========================================================
# Model commands: Surfaces (CRUD)
# ========================================================
func cmd_add_surface(tokens: PackedStringArray) -> void:
	if tokens.size() < 2:
		print_list_item("Usage: add_surface <outer_loop_id> [hole_loop_ids...]")
		return
	var loop_ids: Array[int] = []
	for i: int in range(1, tokens.size()):
		if not tokens[i].is_valid_int():
			print_list_item("Error: loop token '%s' is not an integer ID." % [tokens[i]])
			return
		loop_ids.append(tokens[i].to_int())

	var validation_err: String = model.validate_surface_candidate(loop_ids)
	if not validation_err.is_empty():
		print_list_item("Error: " + validation_err)
		return

	var surface: GGSurface2D = model.add_surface(loop_ids)
	if surface == null:
		print_list_item("Error: failed to create surface.")
		return

	update_status_label()
	gg_viewport.queue_redraw()
	print_list_item("Surface %d created (outer: L%d, holes: %d)." % [
		surface.id, surface.loop_ids[0], surface.loop_ids.size() - 1
	])


func cmd_list_surfaces() -> void:
	if model.surfaces.is_empty():
		print_list_item("No surfaces.")
		return
	for surface: GGSurface2D in model.surfaces:
		var outer_id: int = surface.loop_ids[0]
		var holes_str: String = "none"
		if surface.loop_ids.size() > 1:
			var holes: PackedStringArray = PackedStringArray()
			for i: int in range(1, surface.loop_ids.size()):
				holes.append("L" + str(surface.loop_ids[i]))
			holes_str = ", ".join(holes)
		print_list_item("Surface %d: outer [L%d], holes [%s]" % [
			surface.id, outer_id, holes_str
		])


func cmd_update_surface(tokens: PackedStringArray) -> void:
	if tokens.size() < 3:
		print_list_item("Usage: update_surface <surface_id> <outer_loop_id> [hole_loop_ids...]")
		return
	if not tokens[1].is_valid_int():
		print_list_item("Error: surface_id must be an integer.")
		return
	var surface_id: int = tokens[1].to_int()

	var new_loop_ids: Array[int] = []
	for i: int in range(2, tokens.size()):
		if not tokens[i].is_valid_int():
			print_list_item("Error: loop token '%s' is not an integer ID." % [tokens[i]])
			return
		new_loop_ids.append(tokens[i].to_int())

	var err: String = model.update_surface(surface_id, new_loop_ids)
	if not err.is_empty():
		print_list_item("Error: " + err)
		return

	update_status_label()
	gg_viewport.queue_redraw()
	print_list_item("Surface %d updated successfully." % [surface_id])


func cmd_remove_surface(tokens: PackedStringArray) -> void:
	if tokens.size() != 2 or not tokens[1].is_valid_int():
		print_list_item("Usage: remove_surface <surface_id>")
		return
	var surface_id: int = tokens[1].to_int()
	if not model.remove_surface(surface_id):
		print_list_item("Error: Surface ID %d not found." % [surface_id])
		return
	update_status_label()
	gg_viewport.queue_redraw()
	print_list_item("Surface %d removed." % [surface_id])


func cmd_clear_surfaces() -> void:
	model.clear_surfaces()
	update_status_label()
	gg_viewport.queue_redraw()
	print_list_item("Surfaces cleared.")


func cmd_check_topology() -> void:
	var errors: Array[String] = model.validate_topology()
	if errors.is_empty():
		print_list_item("Topology OK: all lines, loops and surfaces reference valid geometry.")
	else:
		print_list_item("Topology validation failed with %d error(s):" % [errors.size()])
		for err: String in errors:
			print_list_item("  - " + err)


func cmd_export_geo(tokens: PackedStringArray) -> void:
	var target_name: String = ""

	if tokens.size() > 2:
		print_list_item("Usage: export_geo [filename]")
		return

	if tokens.size() == 2:
		if not tokens[1].is_valid_ascii_identifier():
			print_list_item("Error: invalid filename.")
			return
		target_name = tokens[1]
	else:
		print_list_item("No filename provided. Using document name as target.")
		target_name = model.document_name.get_basename()

	if model.export_geo_file(target_name):
		print_line("Exported Gmsh file: user://%s.geo" % [target_name])
	else:
		print_line("Failed to export .geo file.")


# ========================================================
# Shell commands
# ========================================================
func cmd_clear() -> void:
	console_output.text = ""


func cmd_help() -> void:
	print_line("Available commands:")
	print_list_item("help")
	print_list_item("clear")
	print_line("Document commands:")
	print_list_item("new <filename>")
	print_list_item("save")
	print_list_item("load <filename>")
	print_list_item("rename <filename>")
	print_list_item("status")
	print_list_item("history")
	print_list_item("about")
	print_line("Points (0D):")
	print_list_item("list_points")
	print_list_item("add_point <x> <y>")
	print_list_item("move_point <id> <x> <y>")
	print_list_item("remove_point <id>")
	print_list_item("clear_points")
	print_line("Lines (1D):")
	print_list_item("list_lines")
	print_list_item("add_line <p_start> <p_end>")
	print_list_item("remove_line <id>")
	print_list_item("clear_lines")
	print_line("Loops (1D closed):")
	print_list_item("list_loops")
	print_list_item("add_loop <signed_l1> <signed_l2> ...")
	print_list_item("remove_loop <id>")
	print_list_item("clear_loops")
	print_line("Surfaces (2D):")
	print_list_item("list_surfaces")
	print_list_item("add_surface <outer_loop> [hole_loops...]")
	print_list_item("update_surface <id> <outer_loop> [hole_loops...]")
	print_list_item("remove_surface <id>")
	print_list_item("clear_surfaces")
	print_line("Validation and Export:")
	print_list_item("check_topology")
	print_list_item("export_geo [filename]")
	print_line("Viewport commands:")
	print_list_item("zoom_in")
	print_list_item("zoom_out")
	print_list_item("set_zoom <factor>")
	print_list_item("set_pan_offset <x> <y>")
	print_list_item("pan_by <dx> <dy>")
	print_list_item("reset_view")


func cmd_about() -> void:
	print_line("GG CAD Editor prototype")
	print_line("Godot 4 + Gmsh 2D B-Rep engine")


func cmd_status() -> void:
	print_list_item("Document: %s" % [model.document_name])
	print_list_item("Units: %s" % [model.units])
	print_list_item("Dirty: %s" % [str(model.is_dirty)])
	print_list_item("Geometry: %d points, %d lines, %d loops, %d surfaces" % [
		model.points.size(), model.lines.size(), model.loops.size(), model.surfaces.size()
	])


func cmd_history() -> void:
	if command_history.is_empty():
		print_line("Command history is empty.")
		return
	for i: int in range(command_history.size()):
		print_list_item("%d: %s" % [i + 1, command_history[i]])