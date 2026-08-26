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

# InputEventPanGesture.delta передаётся в экранных координатах.
const PAN_GESTURE_SCALE: float = 1.0

# MagnifyGesture.factor близок к 1.0.
# Накопленные 10% жеста преобразуются в один существующий zoom-step.
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
	get_viewport().size_changed.connect(
		_on_viewport_size_changed
	)

	command_line.text_submitted.connect(
		_on_command_submitted
	)

	command_line.gui_input.connect(
		_on_command_line_gui_input
	)

	gg_viewport.gui_input.connect(
		_on_gg_viewport_gui_input
	)


# ========================================================
# Window initialization and diagnostics
# ========================================================

func _print_display_diagnostics() -> void:
	var window: Window = get_window()

	print("=== Display diagnostics ===")
	print("screen: ", window.current_screen)
	print(
		"screen scale: ",
		DisplayServer.screen_get_scale(window.current_screen)
	)
	print(
		"screen DPI: ",
		DisplayServer.screen_get_dpi(window.current_screen)
	)
	print("window size: ", window.size)
	print(
		"viewport size: ",
		get_viewport().get_visible_rect().size
	)
	print("===========================")


func _configure_initial_window() -> void:
	var mode: int = DisplayServer.window_get_mode()

	if mode == DisplayServer.WINDOW_MODE_WINDOWED:
		var screen_id: int = (
			DisplayServer.window_get_current_screen()
		)

		var usable_rect: Rect2i = (
			DisplayServer.screen_get_usable_rect(screen_id)
		)

		var target_width: int = roundi(
			float(usable_rect.size.x) * INITIAL_WIDTH_FRACTION
		)

		var target_height: int = roundi(
			float(target_width) / WINDOW_ASPECT_RATIO
		)

		var max_height: int = roundi(
			float(usable_rect.size.y) * MAX_HEIGHT_FRACTION
		)

		if target_height > max_height:
			target_height = max_height
			target_width = roundi(
				float(target_height) * WINDOW_ASPECT_RATIO
			)

		# Final safety clamp: the requested window must fit
		# the usable screen area.
		target_width = mini(
			target_width,
			usable_rect.size.x
		)

		target_height = mini(
			target_height,
			usable_rect.size.y
		)

		var target_size: Vector2i = Vector2i(
			target_width,
			target_height
		)

		var target_position: Vector2i = (
			usable_rect.position
			+ Vector2i(
				roundi(
					float(
						usable_rect.size.x
						- target_size.x
					) * 0.5
				),
				roundi(
					float(
						usable_rect.size.y
						- target_size.y
					) * 0.5
				)
			)
		)

		DisplayServer.window_set_size(target_size)
		DisplayServer.window_set_position(target_position)

	# Required in windowed, maximized, fullscreen,
	# and exclusive fullscreen modes.
	call_deferred("_update_window_diagnostics")


func _on_viewport_size_changed() -> void:
	call_deferred("_update_window_diagnostics")


func _update_window_diagnostics() -> void:
	var window: Window = get_window()

	var viewport_size: Vector2 = (
		get_viewport().get_visible_rect().size
	)

	var mode: int = DisplayServer.window_get_mode()

	status_label.text = (
		"Mode: %s | Window: %s | Viewport: %s"
		% [
			_get_window_mode_name(mode),
			str(window.size),
			str(viewport_size)
		]
	)


func _get_window_mode_name(mode: int) -> String:
	match mode:
		DisplayServer.WINDOW_MODE_WINDOWED:
			return "windowed"

		DisplayServer.WINDOW_MODE_MAXIMIZED:
			return "maximized"

		DisplayServer.WINDOW_MODE_FULLSCREEN:
			return "fullscreen"

		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			return "exclusive fullscreen"

		_:
			return "unknown"


# ========================================================
# Command-line input
# ========================================================

func _on_command_submitted(command: String) -> void:
	var cmd: String = command.strip_edges()

	print_line("> " + cmd)
	command_line.clear()

	if cmd.is_empty():
		refocus_command_line()
		return

	add_command_to_history(cmd)
	execute_command(cmd)
	refocus_command_line()


func _on_command_line_gui_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event: InputEventKey = (
		event as InputEventKey
	)

	if not key_event.pressed:
		return

	if key_event.echo:
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
		var pan_event := event as InputEventPanGesture
		print(
			"[trackpad] InputEventPanGesture delta = ",
			pan_event.delta
		)
		_handle_viewport_pan_gesture(
			pan_event
		)
		return

	if event is InputEventMagnifyGesture:
		_handle_viewport_magnify_gesture(
			event as InputEventMagnifyGesture
		)
		return

	if event is InputEventMouseButton:
		_handle_viewport_mouse_button(
			event as InputEventMouseButton
		)
		return

	if event is InputEventMouseMotion:
		_handle_viewport_mouse_motion(
			event as InputEventMouseMotion
		)


func _handle_viewport_mouse_button(
	mouse_event: InputEventMouseButton
) -> void:
	match mouse_event.button_index:
		MOUSE_BUTTON_MIDDLE:
			is_mouse_panning = mouse_event.pressed
			gg_viewport.accept_event()

		MOUSE_BUTTON_WHEEL_UP:
			if mouse_event.pressed:
				gg_viewport.zoom_in_at(
					mouse_event.position
				)
				gg_viewport.queue_redraw()
				gg_viewport.accept_event()

		MOUSE_BUTTON_WHEEL_DOWN:
			if mouse_event.pressed:
				gg_viewport.zoom_out_at(
					mouse_event.position
				)
				gg_viewport.queue_redraw()
				gg_viewport.accept_event()


func _handle_viewport_mouse_motion(
	motion_event: InputEventMouseMotion
) -> void:
	if not is_mouse_panning:
		return

	gg_viewport.pan_by(motion_event.relative)
	gg_viewport.queue_redraw()
	gg_viewport.accept_event()


func _handle_viewport_pan_gesture(
	pan_event: InputEventPanGesture
) -> void:
	var pan_delta: Vector2 = (
		-pan_event.delta * PAN_GESTURE_SCALE
	)

	if not pan_delta.is_zero_approx():
		gg_viewport.pan_by(pan_delta)
		gg_viewport.queue_redraw()

	gg_viewport.accept_event()


func _handle_viewport_magnify_gesture(
	magnify_event: InputEventMagnifyGesture
) -> void:
	var event_factor: float = magnify_event.factor

	if event_factor <= 0.0:
		gg_viewport.accept_event()
		return

	var now_msec: int = Time.get_ticks_msec()

	if (
		_last_magnify_event_msec < 0
		or now_msec - _last_magnify_event_msec
		> MAGNIFY_GESTURE_TIMEOUT_MSEC
	):
		_magnify_accumulator = 1.0

	_last_magnify_event_msec = now_msec

	var factor: float = clampf(
		event_factor,
		MIN_MAGNIFY_EVENT_FACTOR,
		MAX_MAGNIFY_EVENT_FACTOR
	)

	_magnify_accumulator *= factor

	var applied_steps: int = 0

	while (
		_magnify_accumulator >= MAGNIFY_STEP_FACTOR
		and applied_steps < MAX_MAGNIFY_STEPS_PER_EVENT
	):
		gg_viewport.zoom_in_at(
			magnify_event.position
		)

		_magnify_accumulator /= MAGNIFY_STEP_FACTOR
		applied_steps += 1

	while (
		_magnify_accumulator
		<= MAGNIFY_INVERSE_STEP_FACTOR
		and applied_steps < MAX_MAGNIFY_STEPS_PER_EVENT
	):
		gg_viewport.zoom_out_at(
			magnify_event.position
		)

		_magnify_accumulator *= MAGNIFY_STEP_FACTOR
		applied_steps += 1

	if applied_steps > 0:
		gg_viewport.queue_redraw()

	gg_viewport.accept_event()


# ========================================================
# Command routing
# ========================================================

func add_command_to_history(cmd: String) -> void:
	command_history.append(cmd)
	history_index = command_history.size()


func execute_command(cmd: String) -> void:
	var tokens: PackedStringArray = cmd.split(
		" ",
		false
	)

	if tokens.is_empty():
		return

	var command_name: String = tokens[0].strip_edges()

	if command_name.is_empty():
		return

	match command_name:
		"help":
			cmd_help()

		"about":
			cmd_about()

		"clear":
			cmd_clear_console()

		"new":
			cmd_new(tokens)

		"history":
			cmd_history()

		"status":
			cmd_status()

		"rename":
			cmd_rename(tokens)

		"list_points":
			cmd_list_points()

		"clear_points":
			cmd_clear_points()

		"add_point":
			cmd_add_point(tokens)

		"move_point":
			cmd_move_point(tokens)

		"remove_point":
			cmd_remove_point(tokens)

		"zoom_in":
			cmd_zoom_in()

		"zoom_out":
			cmd_zoom_out()

		"set_zoom":
			cmd_set_zoom(tokens)

		"set_pan_offset":
			cmd_set_pan_offset(tokens)

		"pan_by":
			cmd_pan_by(tokens)

		"reset_view":
			cmd_reset_view()

		_:
			print_list_item(
				"Unknown command: " + command_name
			)


# ========================================================
# Viewport commands
# ========================================================

func cmd_reset_view() -> void:
	gg_viewport.reset_view()
	gg_viewport.queue_redraw()

	print_list_item(
		"Viewport reset to default zoom and pan offset."
	)


func cmd_pan_by(tokens: PackedStringArray) -> void:
	if tokens.size() != 3:
		print_line(
			"Usage: pan_by <delta_x> <delta_y>"
		)
		return

	var delta_x_text: String = tokens[1]
	var delta_y_text: String = tokens[2]

	if (
		not delta_x_text.is_valid_float()
		or not delta_y_text.is_valid_float()
	):
		print_line("Invalid pan delta values.")
		return

	var delta_x: float = delta_x_text.to_float()
	var delta_y: float = delta_y_text.to_float()

	gg_viewport.pan_by(
		Vector2(delta_x, -delta_y)
	)
	gg_viewport.queue_redraw()

	print_list_item(
		"Panned by (%.2f, %.2f)"
		% [delta_x, delta_y]
	)


func cmd_set_pan_offset(
	tokens: PackedStringArray
) -> void:
	if tokens.size() != 3:
		print_line(
			"Usage: set_pan_offset <x> <y>"
		)
		return

	var x_text: String = tokens[1]
	var y_text: String = tokens[2]

	if (
		not x_text.is_valid_float()
		or not y_text.is_valid_float()
	):
		print_line("Invalid pan offset values.")
		return

	var offset_x: float = x_text.to_float()
	var offset_y: float = y_text.to_float()

	var new_offset: Vector2 = Vector2(
		offset_x,
		-offset_y
	)

	gg_viewport.set_pan_offset(new_offset)
	gg_viewport.queue_redraw()

	print_list_item(
		"Pan offset set to (%.2f, %.2f)"
		% [offset_x, offset_y]
	)


func cmd_set_zoom(tokens: PackedStringArray) -> void:
	if tokens.size() != 2:
		print_line("Usage: set_zoom <zoom_level>")
		return

	if not tokens[1].is_valid_float():
		print_line("Invalid zoom level.")
		return

	var new_zoom: float = tokens[1].to_float()

	gg_viewport.set_zoom(new_zoom)
	gg_viewport.queue_redraw()

	print_list_item(
		"Zoom set to %.2f"
		% [gg_viewport.zoom]
	)


func cmd_zoom_in() -> void:
	gg_viewport.zoom_in()
	gg_viewport.queue_redraw()

	print_list_item(
		"Zoomed in. Current zoom: %.2f"
		% [gg_viewport.zoom]
	)


func cmd_zoom_out() -> void:
	gg_viewport.zoom_out()
	gg_viewport.queue_redraw()

	print_list_item(
		"Zoomed out. Current zoom: %.2f"
		% [gg_viewport.zoom]
	)


# ========================================================
# Model commands
# ========================================================

func cmd_new(tokens: PackedStringArray) -> void:
	if (
		tokens.size() != 2
		or not tokens[1].is_valid_ascii_identifier()
	):
		print_line("Usage: new <filename>")
		return

	model.reset()

	var new_name: String = tokens[1]
	model.document_name = new_name + ".geo"

	print_line(
		"%s document created."
		% [model.document_name]
	)

	status_label.text = model.document_name
	gg_viewport.queue_redraw()


func cmd_rename(tokens: PackedStringArray) -> void:
	if tokens.size() != 2:
		print_line("Usage: rename <filename>")
		return

	var new_name: String = tokens[1]

	model.rename_document(new_name)

	print_line(
		"Document renamed to %s"
		% [new_name]
	)

	status_label.text = model.document_name


func cmd_add_point(
	tokens: PackedStringArray
) -> void:
	if tokens.size() != 3:
		print_list_item(
			"Usage: add_point <x> <y>"
		)
		return

	var x_text: String = tokens[1]
	var y_text: String = tokens[2]

	if not x_text.is_valid_float():
		print_line("Invalid X coordinate.")
		return

	if not y_text.is_valid_float():
		print_line("Invalid Y coordinate.")
		return

	var px: float = x_text.to_float()
	var py: float = y_text.to_float()

	var point: GGPoint2D = model.add_point(px, py)

	status_label.text = model.document_name

	print_list_item(
		"Point %d added."
		% [point.id]
	)

	gg_viewport.queue_redraw()


func cmd_move_point(
	tokens: PackedStringArray
) -> void:
	if tokens.size() != 4:
		print_list_item(
			"Usage: move_point <ID> <x> <y>"
		)
		return

	if not tokens[1].is_valid_int():
		print_list_item(
			"Error: point ID must be an integer"
		)
		return

	if not (
		tokens[2].is_valid_float()
		and tokens[3].is_valid_float()
	):
		print_list_item(
			"Error: coordinates must be valid floats"
		)
		return

	var point_id: int = tokens[1].to_int()
	var x: float = tokens[2].to_float()
	var y: float = tokens[3].to_float()

	if not model.move_point(point_id, x, y):
		print_list_item(
			"Error: point ID not found"
		)
		return

	print_line(
		"Point %d moved to (%.3f, %.3f)."
		% [point_id, x, y]
	)

	gg_viewport.queue_redraw()


func cmd_remove_point(
	tokens: PackedStringArray
) -> void:
	if tokens.size() != 2:
		print_line("Usage: remove_point <ID>")
		return

	if not tokens[1].is_valid_int():
		print_line(
			"Error: point ID must be an integer."
		)
		return

	var point_id: int = tokens[1].to_int()

	if not model.remove_point(point_id):
		print_list_item(
			"Error: point ID not found."
		)
		return

	print_line(
		"Point %d removed."
		% [point_id]
	)

	gg_viewport.queue_redraw()


func cmd_clear_points() -> void:
	model.clear_points()

	print_list_item("Points cleared.")
	gg_viewport.queue_redraw()


func cmd_list_points() -> void:
	if model.points.is_empty():
		print_list_item("No points.")
		return

	for i: int in range(model.points.size()):
		var point: GGPoint2D = model.points[i]
		var point_id: int = point.id

		print_list_item(
			"%d: (%.3f, %.3f)"
			% [
				point_id,
				point.x,
				point.y
			]
		)


# ========================================================
# Shell commands
# ========================================================

func cmd_help() -> void:
	print_line("Available commands:")
	print_list_item("help")
	print_list_item("clear")
	print_list_item("about")
	print_list_item("new")
	print_list_item("history")
	print_list_item("status")
	print_list_item("rename")
	print_list_item("list_points")
	print_list_item("add_point")
	print_list_item("move_point")
	print_list_item("remove_point")
	print_list_item("clear_points")
	print_list_item("zoom_in")
	print_list_item("zoom_out")
	print_list_item("set_zoom")
	print_list_item("set_pan_offset")
	print_list_item("pan_by")
	print_list_item("reset_view")


func cmd_about() -> void:
	print_line("GG Editor prototype")
	print_line("Godot + Gmsh")


func cmd_status() -> void:
	print_list_item(
		"Document: %s"
		% [model.document_name]
	)

	print_list_item(
		"Units: %s"
		% [model.units]
	)

	print_list_item(
		"Dirty: %s"
		% [str(model.is_dirty)]
	)

	print_list_item(
		"Contains: %s points"
		% [str(model.points.size())]
	)


func cmd_history() -> void:
	if command_history.is_empty():
		print_line("Command history is empty.")
		return

	for i: int in range(command_history.size()):
		var item_number: int = i + 1
		var history_item: String = command_history[i]

		print_list_item(
			"%d  %s"
			% [item_number, history_item]
		)


func cmd_clear_console() -> void:
	console_lines.clear()
	console_output.text = ""


# ========================================================
# Console output and history navigation
# ========================================================

func print_line(text: String) -> void:
	console_lines.append(text)
	console_output.text = "\n".join(console_lines)


func print_list_item(text: String) -> void:
	print_line("\t" + text)


func refocus_command_line() -> void:
	command_line.call_deferred("grab_focus")


func show_previous_command() -> void:
	if command_history.is_empty():
		return

	history_index = max(
		0,
		history_index - 1
	)

	command_line.text = (
		command_history[history_index]
	)

	command_line.caret_column = (
		command_line.text.length()
	)


func show_next_command() -> void:
	if command_history.is_empty():
		return

	history_index = min(
		command_history.size(),
		history_index + 1
	)

	if history_index == command_history.size():
		command_line.clear()
	else:
		command_line.text = (
			command_history[history_index]
		)

		command_line.caret_column = (
			command_line.text.length()
		)