extends Control

var command_history: Array[String] = []
var history_index: int = 0

@onready var console_output: TextEdit = %ConsoleOutput
@onready var command_line: LineEdit = %CommandLine
@onready var status_label: Label = %StatusLabel

func _ready() -> void:
	command_line.text_submitted.connect(_on_command_submitted)
	command_line.gui_input.connect(_on_command_line_gui_input)

	print_line("GG CAE shell initialized.")
	print_line("Type 'help' for available commands.")
	command_line.grab_focus()

func print_line(text: String) -> void:
	console_output.text += text + "\n"

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

func execute_command(cmd: String) -> void:
	match cmd:
		"help":
			print_line("Available commands:")
			print_line("help")
			print_line("clear")
			print_line("about")
			print_line("new")
			print_line("history")

		"clear":
			console_output.clear()

		"about":
			print_line("GG CAE prototype")
			print_line("Godot + Gmsh")

		"new":
			print_line("New document created.")
			status_label.text = "Untitled document"

		"history":
			print_command_history()

		_:
			print_line("Unknown command: " + cmd)

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
		print_line("%d  %s" % [item_number, history_item])
