extends PanelContainer
class_name Checklist

signal title_edited(this, old_title, new_title)
signal item_created(this, item, container)
signal item_deleted(this, item, container)
signal item_description_edited(this, item, new_description)
signal item_toggled(this, item)

var item_prefab: PackedScene = preload("res://scenes/checklist_item.tscn") as PackedScene

var old_title: String = ""

@onready var title_edit: LineEdit = Helper.get_descendant_in_group(self, "CLTitleEdit") as LineEdit
@onready var item_container: VBoxContainer = Helper.get_descendant_in_group(self, "CLItemContainer") as VBoxContainer

func set_title(new_title: String) -> void:
	old_title = new_title
	title_edit.text = new_title
	pass

func get_data() -> Dictionary:
	var data: Dictionary = {
		title=title_edit.text,
		items=[],
	}
	for i in item_container.get_children():
		data.items.append(i.get_data())
	
	return data

func load_data(data: Dictionary) -> void:
	assert(data.has("title"), "Checklist data invalid.")
	title_edit.text = data.title
	old_title = data.title
	for i in data.items:
		var item: ChecklistItem = create_item(true) as ChecklistItem
		item.load_data(i.description, i.checked)
	pass

func do_edit_title(new_title: String) -> void:
	if not is_visible_in_tree(): return
	pass

func undo_edit_title(old_title: String) -> void:
	if not is_visible_in_tree(): return
	pass

func do_create_item(item: ChecklistItem) -> void:
	if not is_visible_in_tree(): return
	pass

func undo_create_item(item: ChecklistItem) -> void:
	if not is_visible_in_tree(): return
	pass

func do_delete_item(item: ChecklistItem) -> void:
	if not is_visible_in_tree(): return
	pass

func undo_delete_item(item: ChecklistItem) -> void:
	if not is_visible_in_tree(): return
	pass

func create_item(is_loaded: bool = false) -> ChecklistItem:
	var item: ChecklistItem = item_prefab.instantiate() as ChecklistItem
	item_container.add_child(item)
	if not is_loaded:
		item_created.emit(self, item, item_container)
	item.toggled.connect(on_item_toggled)
	item.description_edited.connect(on_item_description_edited)
	item.deleted.connect(on_item_deleted)
	return item

func on_item_toggled(item: ChecklistItem, checked: bool) -> void:
	item_toggled.emit(self, checked)
	pass

func on_item_description_edited(item: ChecklistItem, new_description: String) -> void:
	item_description_edited.emit(self, item, new_description)
	pass

func on_item_deleted(item: ChecklistItem) -> void:
	item_deleted.emit(self, item, item_container)
	
	pass

func title_focus_exited() -> void:
	if old_title != title_edit.text:
		title_edited.emit(self, old_title, title_edit.text)
		old_title = title_edit.text
	pass # Replace with function body.
























