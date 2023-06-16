extends HBoxContainer
class_name CardComment

signal delete
signal edited

var text: String = "" : get = get_text, set = set_text

@onready var text_edit: TextEdit = Helper.get_descendant_in_group(self, "CCommentText") as TextEdit

func get_text() -> String:
	if not is_instance_valid(text_edit) or text_edit == null: return ""
	return text_edit.text

func set_text(new_text: String) -> void:
	text_edit.text = new_text

func delete_pressed() -> void:
	delete.emit()
	pass # Replace with function body.

func text_edit_focus_exited() -> void:
	edited.emit()
	pass # Replace with function body.
