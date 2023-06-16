extends PanelContainer
class_name ChecklistItem

signal toggled(this, checked)
signal description_edited(this, new_description)
signal deleted(this)

@onready var checkbox: CheckBox = Helper.get_descendant_in_group(self, "CLICheckBox") as CheckBox
@onready var description_edit: TextEdit = Helper.get_descendant_in_group(self, "CLIItemDescription") as TextEdit

var checked: bool = false
var old_description: String = ""

func get_data() -> Dictionary:
	var data: Dictionary = {
		description=description_edit.text,
		checked=checked
	}
	return data

func load_data(description: String, is_checked: bool) -> void:
	if is_checked:
		checkbox.set_pressed_no_signal(is_checked)
	checked = is_checked
	description_edit.text = description
	old_description = description
	pass

func check_box_toggled(button_pressed: bool) -> void:
	checked = button_pressed
	toggled.emit(self, button_pressed)
	pass # Replace with function body.

func set_toggled(is_toggled: bool) -> void:
	checked = is_toggled
	checkbox.set_pressed_no_signal(is_toggled)
	pass

func set_description(new_description: String) -> void:
	old_description = new_description
	description_edit.text = new_description
	pass

func description_focus_exited() -> void:
	if old_description != description_edit.text:
		description_edited.emit(self, description_edit.text)
		old_description = description_edit.text
	pass # Replace with function body.

func delete_pressed() -> void:
	deleted.emit(self)
	pass # Replace with function body.







