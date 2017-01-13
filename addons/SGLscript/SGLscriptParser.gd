var raw_text = ""
var index = 0
var result = []
var macros = {}
var macro_beginnings = []
var caps_header_command = ""
var caps_header_argument = ""

var label_map = {}

var do_macros = true
var do_line_macros = true
var add_paragraph_commands = true

class Command:
    var name = ""
    var arguments = {}

    func to_string():
        if arguments.empty():
            return str("[", name, "]")

        else:
            var argument_part = ""

            for key in arguments.keys():
                argument_part += str(key, ": ")
    
                if typeof(arguments[key]) == TYPE_STRING:
                    argument_part += str("\"", arguments[key], "\"")
                else:
                    argument_part += str(arguments[key])

                argument_part += " "

            return str("[", name, ": ", argument_part.strip_edges(false, true), "]")

class Error:
    var line = 0
    var column = 0
    var message = ""
   
func get_character():
    return raw_text[index]

func get_previous_character():
    if index > 0:
        return raw_text[index-1]
    else:
        return ""
    
func get_next_character():
    if index < raw_text.length():
        return raw_text[index+1]
    else:
        return ""

func next():
    index += 1

func previous():
    index -= 1
    if index < 0: index = 0
    
func in_bounds():
    return index < raw_text.length()

func is_string(thing):
    return typeof(thing) == TYPE_STRING

func is_last_string():
    return is_string(last_item())

func last_item():
    if result.empty():
        return null
    else:
        return result[-1]
    
func add(item):
    result.append(item)
    
func add_character(character):
    if is_last_string():
        result[-1] += character
    else:
        add(character)

func is_whitespace(char):
    return (char == " " or char == "\t" or char == "\n"
            or char == "\r")

func parse_whitespace():
    while is_whitespace(get_character()):
        next()

func parse_line():
    var current_char = ""
    var block = ""

    while in_bounds() and current_char != "\n":
        current_char = get_character()

        if is_whitespace(current_char):
            if block.length() > 0 and block[-1] != " ":
                block += " "
        elif current_char == ";" and get_next_character() == ";":
            while get_character() != "\n":
                next()
            previous()
            break
        else:
            block += current_char

        next()

    return block.strip_edges()

func parse_value():
    var result = ""
    var block = ""
    var current_char = ""

    parse_whitespace()

    # Handle arbitrary amount of comments between arg name and value
    while get_character() == ";" and get_next_character() == ";":
        while get_character() != "\n":
            next()
        parse_whitespace()

    current_char = get_character()

    # Strings
    if current_char == "\"" or current_char == "'":
        var string_starter = current_char
        next()

        while in_bounds():
            current_char = get_character()

            if current_char == "\\":
                next()
                block += get_character()
            elif current_char == string_starter:
                break
            else:
                block += current_char

            next()

    # Other
    else:
        while in_bounds():
            current_char = get_character()

            if is_whitespace(current_char):
                break
            elif current_char == "]" or current_char == ";":
                previous()
                break
            else:
                block += current_char.to_lower()

            next()

        if block.is_valid_integer():
            block = block.to_int()
        elif block.is_valid_float():
            block = block.to_float()

    return block

func parse_command():
    var result = Command.new()
    var current_char = ""
    var block = ""

    next()                      # We started on '['

    # Get command name
    while in_bounds():
        current_char = get_character()
        
        if current_char == ":":
            result.name = block.strip_edges()
            block = ""
            next()
            break
        elif current_char == "]":
            result.name = block.strip_edges()
            return result
        elif is_whitespace(current_char):
            if block.length() > 0 and block[-1] != " ":
                block += " "
        elif current_char == ";" and get_next_character() == ";":
            while get_character() != "\n":
                next()
            previous()
        else:
            block += current_char.to_lower()

        next()

    var argument_name = ""
    var argument_value = ""

    # Get arguments
    while in_bounds():
        current_char = get_character()

        if current_char == ":":
            argument_name = block.strip_edges()
            next()
            argument_value = parse_value()
            result.arguments[argument_name] = argument_value

            block = ""
        elif current_char == "]":
            break
        elif is_whitespace(current_char):
            if block.length() > 0 and block[-1] != " ":
                block += " "
        elif current_char == ";" and get_next_character() == ";":
            while get_character() != "\n":
                next()
            previous()
        else:
            block += current_char.to_lower()

        next()

    return result

func parse(text):
    raw_text = text
    index = 0
    result = []
    macros = {}
    macro_beginnings = []
    label_map = {}
    caps_header_command = ""
    caps_header_argument = ""

    var current_char
    var block
    var line_empty = true
    var paragraph_empty = true
    var suppress_space = false

    while in_bounds():
        current_char = get_character()

        # Escaping
        if current_char == "\\":
            next()
            add_character(get_character())

        # Macros
        elif do_macros and current_char in macro_beginnings:
            var macro_used = false

            for macro in macros.keys():
                if raw_text.substr(index, macro.length()) == macro:
                    # Perform substitution by rebuilding entire string
                    # around it. Is there a better way to do this?
                    raw_text = (
                        raw_text.left(index+1) # part before 
                        # (+1 needed for macro to not get cut off?)
                        + macros[macro]        # + macro text
                        + raw_text.right(      # + part after
                            index+macro.length()
                        ))

                    macro_used = true
                    break

            if not macro_used:
                add_character(current_char)
                line_empty = false

        # Commands
        elif current_char == "[":
            block = parse_command()

            if block.name == "label":
                label_map[block.arguments["name"]] = result.size()
                # Who made arrays use size() insead of length() to get
                # how many items are in them!?

                add(block)

            elif do_macros and block.name == "define macro":
                macros[block.arguments["old"]] = block.arguments["new"]
                macro_beginnings.append(block.arguments["old"][0])

            elif do_line_macros and block.name == "define all caps header handler":
                caps_header_command = block.arguments["command"]
                caps_header_argument = block.arguments["argument"]

            elif block.name == "no space":
                if is_last_string() and last_item()[-1] == " ":
                    result[-1] = result[-1].strip_edges(false, true)
                suppress_space = true

            else:
                add(block)

        # Comments
        elif current_char == ";" and get_next_character() == ";":
            while get_character() != "\n":
                next()
            previous()
            # We want newline to be parsed normally---otherwise
            # adding comments can cause paragraphs to be parsed
            # differently

        # Newlines/paragraph logic
        elif current_char == "\n":
            if line_empty and is_last_string():
                # Prevent paragraphs from ending with whitespace
                if last_item()[-1] == " ":
                    result[-1] = result[-1].strip_edges(false, true)

                if add_paragraph_commands:
                    block = Command.new()
                    block.name = "paragraph"
                    add(block)

                paragraph_empty = true

            line_empty = true

        # Characters to completely ignore
        elif current_char == "\r":
            pass

        # Whitespace logic
        elif current_char == " " or current_char == "\t":
            if ((is_last_string() and last_item()[-1] != " ") or
                (not is_last_string() and not line_empty)):
                if not suppress_space:
                    add_character(current_char)

        # Visible characters
        else:
            # Handle line level macros here
            if do_line_macros:
                # Will only work at beginning of paragraph
                if paragraph_empty:
                    var old_index = index
                    var line_text = parse_line()

                    # Godot has no 'is_upper' :(
                    if (caps_header_command 
                        and line_text == line_text.to_upper()):
                        block = Command.new()
                        block.name = caps_header_command
                        block.arguments[caps_header_argument] = line_text
                        add(block)

                        next()
                        continue
                    else:
                        index = old_index
            
            add_character(current_char)
            suppress_space = false
            line_empty = false
            paragraph_empty = false

        next()
        
    return result
