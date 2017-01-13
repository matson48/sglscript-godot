extends Panel

onready var dialogue = get_node("dialogue_text")
onready var ctc = get_node("ctc")
onready var name = get_node("name_container/name_text")
onready var interpreter = get_node("../")

# Whether to do the typing effect. Initially set to false, so it won't
# try to type things before any text has been added.
var do_typing = false

func _ready():
    # Typing one letter per frame at 60 FPS nearly always looks good,
    # in my opinion
    set_fixed_process(true)

    # Usually [paragraph] command will hide all the text in the text
    # box, but that won't happen for the first line of dialogue, so we
    # need to do it manually here
    dialogue.set_visible_characters(0)

func _fixed_process(dt):
    if do_typing:
        var amount = dialogue.get_visible_characters()

        # When current block of text has finished typing, continue on
        # with script execution
        if amount == dialogue.get_total_character_count():
            interpreter.advance()
            do_typing = false

        # Otherwise display one more character
        else:
            amount += 1
            dialogue.set_visible_characters(amount)

# Bound to clicking the text box
func advance():
     # If being paused by [paragraph], clear text and move on with script
     if interpreter.pause_code == 1:
         dialogue.clear()
         dialogue.set_visible_characters(0) 
         # Amount of visible characters is actually not cleared with
         # clear(). Should it be? :\

         interpreter.advance()

func handle_text(text):
     # Add the text (will be invisible at this point)
     dialogue.add_text(text)

     # Pause with code that means we're waiting for animations to
     # finish playing
     interpreter.pause(2)

     # Hide click-to-continue animation
     ctc.hide()

     # Start typing out the text
     do_typing = true

func sgl_command_paragraph(arguments):
     # Pause with code that means we're waiting for user input
     interpreter.pause(1)       

     # Show click-to-continue animation, to make that clear to user
     ctc.show()

# Command for setting the name of the current speaker
func sgl_command_set_name(arguments):
     name.set_text(arguments["name"].capitalize())

