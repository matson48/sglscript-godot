extends Panel

onready var dialogue = get_node("dialogue_text")
onready var name = get_node("name_container/name_text")
onready var interpreter = get_node("../")

func advance():
     if interpreter.pause_code == 1:
         dialogue.clear()
         interpreter.advance()

func handle_text(text):
     dialogue.add_text(text)

func sgl_command_paragraph(arguments):
     interpreter.pause(1)

func sgl_command_name(arguments):
     name.set_text(arguments["name"].capitalize())

