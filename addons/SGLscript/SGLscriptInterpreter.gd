extends Node

onready var parser = preload("SGLscriptParser.gd").new()

export(String, FILE, "*.sglscript") var filename = ""
export var auto_start = false

var script_text = ""
var script = []
var label_map = {}

var index = 0
var paused = true
var pause_code = -1
var in_command_loop = false
var label_command = null
var label_index = 0

func _ready():
    if filename:
        load_file(filename)

func load_file(script_filename):
    filename = script_filename

    var file = File.new()
    file.open(filename, file.READ)
    script_text = file.get_as_text()
    file.close()

    prepare_script()

func load_text(text):
    filename = ""

    script_text = text

    prepare_script()

# Users: don't call this
func prepare_script():
    script = parser.parse(script_text)
    label_map = parser.label_map

    index = 0
    if auto_start:
        advance()

func in_bounds():
    return index < script.size()

func get_current():
    return script[index]

func is_current_command():
    return get_current() extends parser.Command

func is_current_text():
    return typeof(get_current()) == TYPE_STRING

func next():
    # if index+1 < script.size():
    index += 1

func previous():
    if index - 1 > 0:
        index -= 1

func advance():
    var current

    paused = false
    pause_code = 0
    
    in_command_loop = true

    while in_bounds():
        current = get_current()

        if is_current_text():
            handle_text(current)
        elif is_current_command():
            if current.name == "label":
                label_command = get_current()
                label_index = index
            else:
                handle_command(current)
        else:
            pass # hell has frozen over

        next()

        if paused: 
            break

    in_command_loop = false

func pause(code):
    paused = true
    pause_code = code

func goto_label(name):
    if label_map.has(name):
        index = label_map[name]
        if in_command_loop: previous()
    else:
        printerr("SGLscript Warning: No such label '", name, "'. Not jumping")

# Users: don't call these, but overriding them is fine
func handle_command(command):
    var command_name = str("sgl_command_", command.name.replace(" ", "_"))

    if has_method(command_name):
        call(command_name, command.arguments)
        return true
    else:
        for item in get_children():
            if item.has_method(command_name):
                item.call(command_name, command.arguments)
                return true

        printerr("SGLscript Warning: No such command '", command.name, "'. Ignoring it")
        return false

func handle_text(text):
    for item in get_children():
        if item.has_method("handle_text"):
            item.call("handle_text", text)
            return true

    printerr("SGLscript Warning: No 'handle_text' method available. All text is being ignored")
    return false


