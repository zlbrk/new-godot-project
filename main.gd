extends Control

var command_history: Array[String] = []
var console_lines: Array[String] = []
var history_index: int = 0
var model: GGModel

@onready var console_output: RichTextLabel = %ConsoleOutput
@onready var command_line: LineEdit = %CommandLine
@onready var status_label: Label = %StatusLabel

func _ready() -> void:
	model = GGModel.new()
	command_line.text_submitted.connect(_on_command_submitted)
	command_line.gui_input.connect(_on_command_line_gui_input)

	print_line("GG Editor shell initialized.")
	print_line("Type 'help' for available commands.")
	command_line.grab_focus()

func execute_command(cmd: String) -> void:
	var parts: PackedStringArray = cmd.split(" ", false)

	if parts.is_empty():
		return

	var command_name: String = parts[0].strip_edges()
	if command_name.is_empty():
		return
	match command_name:
		"help":
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
			print_list_item("clear_points")

		"clear":
			clear_console()

		"about":
			print_line("GG Editor prototype")
			print_line("Godot + Gmsh")

		"new":
			model.reset()
			print_list_item("%s document created." % [model.document_name])
			status_label.text = model.document_name

		"history":
			print_command_history()

		"status":
			print_model_status()

		"rename":
			if parts.size() < 2:
				print_list_item("Usage: rename <filename>")
				return
			var new_name: String = parts[1]
			model.document_name = new_name
			model.is_dirty = true
			status_label.text = model.document_name
			print_list_item("Document renamed to %s" % [new_name])

		"list_points":
			print_points()

		"clear_points":
			model.clear_points()
			print_list_item("Points cleared.")

		"add_point":
			if parts.size() < 3:
				print_list_item("Usage: add_point <x> <y>")
				return

			var x_text: String = parts[1]
			var y_text: String = parts[2]

			if not x_text.is_valid_float():
				print_line("Invalid X coordinate.")
				return

			if not y_text.is_valid_float():
				print_line("Invalid Y coordinate.")
				return

			var px: float = x_text.to_float()
			var py: float = y_text.to_float()

			model.add_point(px, py)
			status_label.text = model.document_name
			print_list_item("Point %d added." % [model.points.size()])

		_:
			print_list_item("Unknown command: " + command_name)

func print_points() -> void:
	if model.points.is_empty():
		print_list_item("No points.")
		return

	for i: int in range(model.points.size()):
		var point: GGPoint2D = model.points[i]
		var point_number: int = i + 1
		print_list_item("%d: (%.3f, %.3f)" % [point_number, point.x, point.y])

func print_line(text: String) -> void:
	console_lines.append(text)
	console_output.text = "\n".join(console_lines)

func clear_console() -> void:
	console_lines.clear()
	console_output.text = ""

func print_list_item(text: String) -> void:
	print_line("\t" + text)

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

func add_command_to_history(cmd: String) -> void:
	command_history.append(cmd)

	history_index = command_history.size()

# func execute_command(cmd: String) -> void:


func print_model_status() -> void:
	print_list_item("Document: %s" % [model.document_name])
	print_list_item("Units: %s" % [model.units])
	print_list_item("Dirty: %s" % [str(model.is_dirty)])

func refocus_command_line() -> void:
	command_line.call_deferred("grab_focus")

func _on_command_line_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event

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

func show_previous_command() -> void:
	if command_history.is_empty():
		return

	history_index = max(0, history_index - 1)
	command_line.text = command_history[history_index]
	command_line.caret_column = command_line.text.length()

func show_next_command() -> void:
	if command_history.is_empty():
		return

	history_index = min(command_history.size(), history_index + 1)

	if history_index == command_history.size():
		command_line.clear()
	else:
		command_line.text = command_history[history_index]
		command_line.caret_column = command_line.text.length()

func print_command_history() -> void:
	if command_history.is_empty():
		print_line("Command history is empty.")
		return

	for i: int in range(command_history.size()):
		var item_number: int = i + 1
		var history_item: String = command_history[i]
		print_list_item("%d  %s" % [item_number, history_item])
