extends PanelContainer
class_name CardTag

signal remove_tag(this, tag)
signal tag_updated(old_tag, new_tag)

var current_tag: String = ""

@onready var line_edit: LineEdit = Helper.get_descendant_in_group(self, "CTLineEdit") as LineEdit

func start(tag: String, existing_tag: bool) -> void:
	if tag == "" or not existing_tag:
		existing_tag = false
		line_edit.grab_focus()
	else:
		line_edit.text = tag
	current_tag = tag
	pass

func _input(event: InputEvent) -> void:
	if line_edit.has_focus():
		if event.is_action_released("ui_accept") or event.is_action_released("ui_cancel"): line_edit.release_focus()
	pass

func remove_tag_pressed() -> void:
	emit_signal("remove_tag", self, current_tag)
	pass # Replace with function body.


func line_edit_focus_exited() -> void:
	if current_tag != line_edit.text:
		emit_signal("tag_updated", current_tag, line_edit.text)
		current_tag = line_edit.text
	pass # Replace with function body.
