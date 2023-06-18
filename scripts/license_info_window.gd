extends PanelContainer

@onready var starboard_info: Label = Helper.get_descendant_in_group(self, "LIStarboardInfo") as Label
@onready var element_info: Label = Helper.get_descendant_in_group(self, "LIElementInfo") as Label
@onready var calendar_info: Label = Helper.get_descendant_in_group(self, "LICalendarInfo") as Label

func _input(event: InputEvent) -> void:
	if not visible: return
	if Input.is_action_just_released("mouse_left"):
		if not Helper.is_mouse_hovering_control(self):
			exit_pressed()
	if Input.is_action_just_pressed("escape_key"):
		exit_pressed()
	pass

func open() -> void:
	if not visible: show()
	if not get_parent().visible: get_parent().show()
	pass

func exit_pressed() -> void:
	if visible: hide()
	if get_parent().visible: get_parent().hide()
	pass # Replace with function body.

func starboard_toggled(toggled: bool) -> void:
	starboard_info.visible = toggled
	pass # Replace with function body.

func element_toggled(toggled: bool) -> void:
	element_info.visible = toggled
	pass # Replace with function body.

func calendar_toggled(toggled: bool) -> void:
	calendar_info.visible = toggled
	pass # Replace with function body.
