extends Panel

onready var dialogue = get_node("dialogue")
onready var interpreter = get_node("../")

func advance():
     if interpreter.pause_code == 1:
         interpreter.advance()

func handle_text(text):
     dialogue.set_text(text)

func sgl_command_paragraph(arguments):
     interpreter.pause(1)


