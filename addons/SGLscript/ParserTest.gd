extends Panel

onready var parser = preload("SGLscriptParser.gd").new()

func on_load_script():
    var list = get_node("./Splitter/Left/ItemList")
    var label = get_node("./Splitter/Right/RichTextLabel")
    list.clear()
    label.clear()

    var file = File.new()
    file.open("ParserScript.sglscript", file.READ)
    var text = file.get_as_text()
    file.close()

    label.add_text(text)

    var script = parser.parse(text)
    var index = 0
    for item in script:
        if typeof(item) == TYPE_STRING:
            list.add_item(str(index, ": ", "\"", item, "\""))
        elif item extends parser.Command:
            list.add_item(str(index, ": ", item.to_string())) 
        index += 1

    label.add_text(str("\n",parser.label_map))

