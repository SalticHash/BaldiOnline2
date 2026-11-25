extends Node
class_name ScrollMobile
@onready var gui: Node = get_parent()

func _ready() -> void:
	if gui is not ItemList:
		push_error("ScrollMobile not attached as a child if an ItemList node")
		return
	gui.gui_input.connect(gui_input)

func gui_input(event: InputEvent):
	if event is not InputEventScreenDrag: return
	gui.get_v_scroll_bar().value += -event.relative.y
