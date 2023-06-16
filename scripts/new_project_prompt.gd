extends PanelContainer
class_name NewProjectPrompt

signal create_project(title)

@onready var title_edit: LineEdit = Helper.get_descendant_in_group(self, "NPPTitleEdit") as LineEdit

func open() -> void:
	if not visible: show()
	if not get_parent().visible: get_parent().show()
	pass

func _input(event: InputEvent) -> void:
	if not visible: return
	if not get_parent().visible: return
	if event.is_action_released("ui_cancel"):
		if not title_edit.has_focus():
			cancel_pressed()
		else:
			title_edit.release_focus()
	pass

func create_pressed() -> void:
	emit_signal("create_project", title_edit.text)
	cancel_pressed()
	pass # Replace with function body.


func cancel_pressed() -> void:
	if visible: hide()
	if get_parent().visible: get_parent().hide()
	title_edit.text = ""
	pass # Replace with function body.
