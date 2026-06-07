extends Control

var command_history: Array[String] = []
var console_lines: Array[String] = []
var history_index: int = 0
var model: GGModel

@onready var console_output: RichTextLabel = %ConsoleOutput
@onready var command_line: LineEdit = %CommandLine
@onready var status_label: Label = %StatusLabel

# Godot specific private function for main CLI widget init
func _ready() -> void:
	model = GGModel.new()
	command_line.text_submitted.connect(_on_command_submitted)
	command_line.gui_input.connect(_on_command_line_gui_input)

	print_line("GG Editor shell initialized.")
	print_line("Type 'help' for available commands.")
	refocus_command_line()

# Private CLI functions
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

# User functions
func add_command_to_history(cmd: String) -> void:
	command_history.append(cmd)
	history_index = command_history.size()

func execute_command(cmd: String) -> void:
	var tokens: PackedStringArray = cmd.split(" ", false)
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

		_:
			print_list_item("Unknown command: " + command_name)
# ========================================================
# Implementations
# ========================================================
func cmd_remove_point(tokens: PackedStringArray) -> void:
	if tokens.size() != 2:
		print_line("Usage: remove_point <index>")
		return
	if not tokens[1].is_valid_int():
		print_line("Error: point index must be an integer.")
		return
	var user_index: int = tokens[1].to_int()
	if not model.remove_point(user_index):
		print_line("Error: point index out of range.")
		return
	print_line("Point %d removed." % [user_index])


func cmd_about() -> void:
	print_line("GG Editor prototype")
	print_line("Godot + Gmsh")


func cmd_new(tokens: PackedStringArray) -> void:
	if tokens.size() != 2 or not tokens[1].is_valid_ascii_identifier():
		print_line("Usage: new <filename>")
		return
	model.reset()
	var new_name: String = tokens[1]
	model.document_name = new_name + ".geo"
	print_line("%s document created." % [model.document_name])
	status_label.text = model.document_name


func cmd_rename(tokens: PackedStringArray) -> void:
	if tokens.size() != 2:
		print_line("Usage: rename <filename>")
		return
	var new_name: String = tokens[1]
	model.rename_document(new_name)
	print_line("Document renamed to %s" % [new_name])


func cmd_clear_points() -> void:
	model.clear_points()
	print_list_item("Points cleared.")


func cmd_add_point(tokens: PackedStringArray) -> void:
	if tokens.size() != 3:
		print_list_item("Usage: add_point <x> <y>")
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
	model.add_point(px, py)
	status_label.text = model.document_name
	print_list_item("Point %d added." % [model.points.size()])


func cmd_move_point(tokens: PackedStringArray) -> void:
	if tokens.size() != 4:
		print_list_item("Usage: move_point <index> <x> <y>")
		return
	if not tokens[1].is_valid_int():
		print_list_item("Error: point index must be an integer")
		return
	if not (tokens[2].is_valid_float() and tokens[3].is_valid_float()):
		print_list_item("Error: coordinates must be valid floats")
		return
	var user_index: int = tokens[1].to_int()
	var x: float = tokens[2].to_float()
	var y: float = tokens[3].to_float()

	if not model.move_point(user_index, x, y):
		print_list_item("Error: point index is out of range")
		return

	print_line("Point %d moved to (%.3f, %.3f)." % [user_index, x, y])


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


func print_line(text: String) -> void:
	console_lines.append(text)
	console_output.text = "\n".join(console_lines)


func print_list_item(text: String) -> void:
	print_line("\t" + text)


func cmd_clear_console() -> void:
	console_lines.clear()
	console_output.text = ""


func cmd_list_points() -> void:
	if model.points.is_empty():
		print_list_item("No points.")
		return

	for i: int in range(model.points.size()):
		var point: GGPoint2D = model.points[i]
		var point_number: int = i + 1
		print_list_item("%d: (%.3f, %.3f)" % [point_number, point.x, point.y])


func refocus_command_line() -> void:
	command_line.call_deferred("grab_focus")


func cmd_status() -> void:
	print_list_item("Document: %s" % [model.document_name])
	print_list_item("Units: %s" % [model.units])
	print_list_item("Dirty: %s" % [str(model.is_dirty)])
	print_list_item("Contains: %s points" % [str(model.points.size())])


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


func cmd_history() -> void:
	if command_history.is_empty():
		print_line("Command history is empty.")
		return
	for i: int in range(command_history.size()):
		var item_number: int = i + 1
		var history_item: String = command_history[i]
		print_list_item("%d  %s" % [item_number, history_item])
