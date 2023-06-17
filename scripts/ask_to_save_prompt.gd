extends PanelContainer
class_name AskToSavePrompt

signal response_confirmed(response, project, tab_index)

var project: Project = null
var tab_index: int = -1

func open(_project: Project, tab_idx: int) -> void:
	project = _project
	tab_index = tab_idx
	if not visible: show()
	if not get_parent().visible: get_parent().show()
	pass

#func _input(event: InputEvent) -> void:
#	if not visible: return
#	if not get_parent().visible: return
#	if event.is_action_released("ui_cancel"):
#		if not title_edit.has_focus():
#			cancel_pressed()
#		else:
#			title_edit.release_focus()
#	pass

func save_pressed() -> void:
	response_confirmed.emit(0, project, tab_index)
	close()
	pass # Replace with function body.

func discard_pressed() -> void:
	response_confirmed.emit(1, project, tab_index)
	close()
	pass

func cancel_pressed() -> void:
	response_confirmed.emit(2, project, tab_index)
	close()
	pass # Replace with function body.

func close() -> void:
	project = null
	tab_index = -1
	if visible: hide()
	if get_parent().visible: get_parent().hide()
	pass
