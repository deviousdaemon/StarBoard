extends PanelContainer
class_name DependancyLabel

var text: String = "" : set = set_text

@onready var label: Label = Helper.get_descendant_in_group(self, "DPLabel") as Label

func set_text(new_text: String) -> void:
	text = new_text
	label.text = new_text
	pass
