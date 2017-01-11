extends Spatial

onready var interpreter = get_node("../")
onready var message_window = get_node("../mwin")

func sgl_command_play_animation(arguments):
     get_node("3d_anims").play(arguments["name"])
     interpreter.pause(2)
     message_window.hide()

func animation_finished():
     message_window.show()
     interpreter.advance()

