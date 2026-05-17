extends Control


@onready var console_output: TextEdit = %ConsoleOutput
@onready var command_line: LineEdit = %CommandLine
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
 command_line.text_submitted.connect(_on_command_submitted)

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
  command_line.grab_focus()
  return

 match cmd:
  "help":
   print_line("Available commands:")
   print_line("help")
   print_line("clear")
   print_line("about")
   print_line("new")
   

  "clear":
   console_output.clear()
   

  "about":
   print_line("GG CAE prototype")
   print_line("Godot + Gmsh")
   

  "new":
   print_line("New document created.")
   status_label.text = "Untitled document"
   

  _:
   print_line("Unknown command: " + cmd)
 refocus_command_line() 
 
func refocus_command_line() -> void:
   command_line.call_deferred("grab_focus")
