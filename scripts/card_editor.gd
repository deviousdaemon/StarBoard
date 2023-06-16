extends PanelContainer
class_name CardEditor

signal card_tag_removed(card, tag)
signal card_tag_updated(card, old_tag, new_tag)
signal card_tag_added(card, tag)
signal card_edit_dependancies(card)

var comment_prefab: PackedScene = preload("res://scenes/card_comment.tscn") as PackedScene
var tag_prefab: PackedScene = preload("res://scenes/card_tag.tscn") as PackedScene
var dependancy_label_prefab: PackedScene = preload("res://scenes/dependancy_label.tscn") as PackedScene
var checklist_prefab: PackedScene = preload("res://scenes/checklist.tscn") as PackedScene

var current_project: Project = null
var undo_redo: UndoRedo = null
var current_card: Card = null
var current_tags: Dictionary = {}

@onready var title_edit: LineEdit = Helper.get_descendant_in_group(self, "CETitle")
@onready var description_edit: TextEdit = Helper.get_descendant_in_group(self, "CEDescription")
@onready var dependencies_container: HFlowContainer = Helper.get_descendant_in_group(self, "CEDependenciesContainer") as HFlowContainer
@onready var comment_container: VBoxContainer = Helper.get_descendant_in_group(self, "CECommentContainer") as VBoxContainer
@onready var checklist_container: VBoxContainer = Helper.get_descendant_in_group(self, "CEChecklistContainer") as VBoxContainer
@onready var tag_container: VBoxContainer = Helper.get_descendant_in_group(self, "CETagContainer") as VBoxContainer
@onready var add_tag_menu: PopupMenu = Helper.get_descendant_in_group(self, "CEAddTag").get_popup() as PopupMenu
@onready var calendar_button: CalendarButton = Helper.get_descendant_in_group(self, "CECalendarButton") as CalendarButton

func delete() -> void:
	calendar_button.popup.propagate_call("queue_free")
	calendar_button.popup.queue_free()
	propagate_call("queue_free")
	queue_free()
	pass

func hide_all() -> void:
	visible = false
	get_parent().hide()
	pass

func show() -> void:
	visible = true
	get_parent().show()
	pass

func _ready() -> void:
#	close_pressed()
#	comment_container.hide()
#	checklist_container.hide()
	focus_entered.connect(release_focus)
	add_tag_menu.id_pressed.connect(add_tag_menu_button_pressed)
	pass

func _input(event: InputEvent) -> void:
	if not visible: return
	if Input.is_action_just_released("mouse_left"):
		if not Helper.is_mouse_hovering_control(self):
			close_pressed()
	if Input.is_action_just_pressed("escape_key"):
		if not (is_instance_valid(get_viewport().gui_get_focus_owner()) and is_ancestor_of(get_viewport().gui_get_focus_owner())):
			close_pressed()
	pass

func open(project: Project, card: Card, tags: Dictionary) -> void:
#	await get_tree().process_frame
	reset()
#	print("a")
	current_project = project
	undo_redo = project.undo_redo
	current_card = card
	current_tags = tags
	var card_data: Dictionary = card.get_card_data()
	title_edit.text = card_data.title
	description_edit.text = card_data.description
	if is_instance_valid(card.due_date):
		calendar_button.text = card.due_date.date("MM-DD-YYYY")
	else:
		calendar_button.text = "None"
	for i in tags.keys():
		var cards: Array = tags[i]
		var has_tag: bool = false
		for j in cards:
			if j.card_id == card.card_id: has_tag = true
		if has_tag:
			var tag: CardTag = tag_prefab.instantiate() as CardTag
			tag_container.add_child(tag)
			tag.connect("remove_tag", remove_tag)
			tag.connect("tag_updated", tag_updated)
			tag.start(i, true)
		else:
			add_tag_menu.add_item(i)
			pass
	if add_tag_menu.item_count < 1: add_tag_menu.get_parent().hide()
	
	for i in card_data.comments:
		var comment: CardComment = add_comment_pressed(true) as CardComment
#		comment_container.add_child(comment)
		comment.set_text(i)
	
	
	
	if comment_container.get_child_count() > 1: comment_container.show()
	
	for i in card.dependencies:
		var d_card: Card = project.get_card_by_id(i)
		var dependancy_label: DependancyLabel = dependancy_label_prefab.instantiate() as DependancyLabel
		dependencies_container.add_child(dependancy_label)
		dependancy_label.text = d_card.title
		pass
	
	for i in card.checklists:
		var checklist: Checklist = create_checklist(true) as Checklist
		checklist.load_data(i)
		pass
	
	
	if not visible or not get_parent().visible: self.show()
	pass

func create_checklist(is_loaded: bool = false) -> Checklist:
	var checklist: Checklist = checklist_prefab.instantiate() as Checklist
	if is_loaded:
		checklist_container.add_child(checklist)
		checklist.title_edited.connect(checklist_title_edited)
		checklist.item_created.connect(checklist_item_created)
		checklist.item_toggled.connect(checklist_item_toggled)
		checklist.item_description_edited.connect(checklist_item_description_edited)
		checklist.item_deleted.connect(checklist_item_deleted)
		return checklist
	else:
		undo_redo.create_action("Create Checklist on card " + current_card.title)
		var old_data: Array[Dictionary] = current_card.checklists.duplicate(true)
		var cl_data: Array[Dictionary] = current_card.checklists.duplicate(true)
		cl_data.append({
			title="",
			items=[]
		})
		current_card.checklists = cl_data
		undo_redo.add_undo_property(current_card, "checklists", old_data)
		undo_redo.add_do_property(current_card, "checklists", cl_data.duplicate(true))
		undo_redo.add_do_method(open.bind(current_project, current_card, current_tags))
		undo_redo.add_undo_method(open.bind(current_project, current_card, current_tags))
		current_project.commit_undo_redo_action()
		open(current_project, current_card, current_tags)
		return null
#		undo_redo.add_do_reference(checklist)
#		undo_redo.add_do_method(checklist_container.add_child.bind(checklist))
#		undo_redo.add_undo_method(checklist_container.remove_child.bind(checklist))
		pass
	
	
	
	return checklist

func checklist_title_edited(checklist: Checklist, old_title: String, new_title: String) -> void:
	var old_data: Array[Dictionary] = current_card.checklists.duplicate(true)
	var new_data: Array[Dictionary] = old_data.duplicate(true)
	new_data[checklist.get_index()].title = new_title
	current_card.checklists = new_data
	undo_redo.create_action("Checklist Title Edited on card " + current_card.title)
	undo_redo.add_do_property(current_card, "checklists", new_data)
	undo_redo.add_undo_property(current_card, "checklists", old_data)
	undo_redo.add_do_method(open.bind(current_project, current_card, current_tags))
	undo_redo.add_undo_method(open.bind(current_project, current_card, current_tags))
	
#	undo_redo.add_do_method(checklist.set_title.bind(new_title))
#	undo_redo.add_undo_method(checklist.set_title.bind(old_title))
	current_project.commit_undo_redo_action()
	open(current_project, current_card, current_tags)
	pass

func checklist_item_created(checklist:Checklist, item: ChecklistItem, container: BoxContainer) -> void:
	var old_data: Array[Dictionary] = current_card.checklists.duplicate(true)
	var new_data: Array[Dictionary] = old_data.duplicate(true)
	new_data[checklist.get_index()].items.append(item.get_data())
	current_card.checklists = new_data
	undo_redo.create_action("Checklist Item Created on card " + current_card.title)
	undo_redo.add_do_property(current_card, "checklists", new_data)
	undo_redo.add_undo_property(current_card, "checklists", old_data)
	undo_redo.add_do_method(open.bind(current_project, current_card, current_tags))
	undo_redo.add_undo_method(open.bind(current_project, current_card, current_tags))
#	undo_redo.add_do_reference(item)
#	undo_redo.add_do_method(container.add_child.bind(item))
#	undo_redo.add_undo_method(container.remove_child.bind(item))
	current_project.commit_undo_redo_action()
	open(current_project, current_card, current_tags)
	pass

func checklist_item_deleted(checklist: Checklist, item: ChecklistItem, container: BoxContainer) -> void:
	var old_data: Array[Dictionary] = current_card.checklists.duplicate(true)
	var new_data: Array[Dictionary] = old_data.duplicate(true)
	new_data[checklist.get_index()].items.remove_at(item.get_index())
	current_card.checklists = new_data
	undo_redo.create_action("Checklist Item Deleted on card " + current_card.title)
	undo_redo.add_do_property(current_card, "checklists", new_data)
	undo_redo.add_undo_property(current_card, "checklists", old_data)
	undo_redo.add_do_method(open.bind(current_project, current_card, current_tags))
	undo_redo.add_undo_method(open.bind(current_project, current_card, current_tags))
#	undo_redo.add_undo_reference(item)
#	undo_redo.add_do_method(container.remove_child.bind(item))
#	undo_redo.add_undo_method(container.add_child.bind(item))
	current_project.commit_undo_redo_action()
	item.queue_free()
	open(current_project, current_card, current_tags)
	pass

func checklist_item_toggled(checklist: Checklist, item: ChecklistItem, checked: bool) -> void:
	var old_data: Array[Dictionary] = current_card.checklists.duplicate(true)
	var new_data: Array[Dictionary] = old_data.duplicate(true)
	new_data[checklist.get_index()].items[item.get_index()].checked = checked
	current_card.checklists = new_data
	undo_redo.create_action("Checklist Item Toggled on card " + current_card.title)
	undo_redo.add_do_property(current_card, "checklists", new_data)
	undo_redo.add_undo_property(current_card, "checklists", old_data)
	undo_redo.add_do_method(open.bind(current_project, current_card, current_tags))
	undo_redo.add_undo_method(open.bind(current_project, current_card, current_tags))
#	undo_redo.add_do_method(item.set_toggled.bind(checked))
#	undo_redo.add_undo_method(item.set_toggled.bind(!checked))
	current_project.commit_undo_redo_action()
	open(current_project, current_card, current_tags)
	pass

func checklist_item_description_edited(checklist: Checklist, item: ChecklistItem, new_d: String) -> void:
	var old_data: Array[Dictionary] = current_card.checklists.duplicate(true)
	var new_data: Array[Dictionary] = old_data.duplicate(true)
	new_data[checklist.get_index()].items[item.get_index()].description = new_d
	current_card.checklists = new_data
	undo_redo.create_action("Checklist Item Description Edited on card " + current_card.title)
	undo_redo.add_do_property(current_card, "checklists", new_data)
	undo_redo.add_undo_property(current_card, "checklists", old_data)
	undo_redo.add_do_method(open.bind(current_project, current_card, current_tags))
	undo_redo.add_undo_method(open.bind(current_project, current_card, current_tags))
#	undo_redo.add_do_method(item.set_description.bind(old_d))
#	undo_redo.add_undo_method(item.set_description.bind(new_d))
	current_project.commit_undo_redo_action()
	open(current_project, current_card, current_tags)
	pass

func add_tag_menu_button_pressed(id: int) -> void:
	var t_tag: String = add_tag_menu.get_item_text(id)
	var tag: CardTag = tag_prefab.instantiate() as CardTag
	tag_container.add_child(tag)
	tag.connect("remove_tag", remove_tag)
	tag.connect("tag_updated", tag_updated)
	tag.start(t_tag, true)
	add_tag_menu.remove_item(add_tag_menu.get_item_index(id))
	card_tag_added.emit(current_card, t_tag)
	pass

func remove_tag(card_tag: CardTag, tag: String) -> void:
	if not tag.is_empty():
		card_tag_removed.emit(current_card, tag)
	card_tag.queue_free()
	pass

func tag_updated(old_tag: String, new_tag: String) -> void:
	card_tag_updated.emit(current_card, old_tag, new_tag)
	pass

func create_tag_pressed() -> void:
	var tag: CardTag = tag_prefab.instantiate() as CardTag
	tag_container.add_child(tag)
	tag.connect("remove_tag", remove_tag)
	tag.connect("tag_updated", tag_updated)
	tag.start("", false)
	pass # Replace with function body.

func close_pressed() -> void:
	if is_instance_valid(get_viewport().gui_get_focus_owner()):
		get_viewport().gui_get_focus_owner().release_focus()
	if visible: hide_all()
	
	reset()
	
	current_card = null
	pass # Replace with function body.


func reset() -> void:
	title_edit.text = ""
	description_edit.text = ""
	
	
	var comments: Array[String] = []
#	for i in comment_container.get_children():
#		comments.append(i.text)
#	if is_instance_valid(current_card):
#		current_card.comments = comments
	for i in tag_container.get_children(): i.queue_free()
	for i in dependencies_container.get_children(): i.queue_free()
	for i in checklist_container.get_children(): i.queue_free()
	for i in comment_container.get_children(): i.queue_free()
	add_tag_menu.get_parent().show()
	add_tag_menu.clear()
	pass

func title_focus_exited() -> void:
	if current_card.title != title_edit.text:
		var old_title = current_card.title
		current_card.title = title_edit.text
		undo_redo.create_action("Description Edited on card: " + current_card.title)
		undo_redo.add_do_property(current_card, "title", title_edit.text)
		undo_redo.add_undo_property(current_card, "title", old_title)
		undo_redo.add_do_method(open.bind(current_project, current_card, current_tags))
		undo_redo.add_undo_method(open.bind(current_project, current_card, current_tags))
		current_project.commit_undo_redo_action()
		open(current_project, current_card, current_tags)
#		undo_redo.create_action("Title Edited on card: " + current_card.title)
#		undo_redo.add_do_method(do_edit_title.bind(current_card, title_edit.text))
#		undo_redo.add_undo_method(undo_edit_title.bind(current_card, current_card.title))
#		current_project.commit_undo_redo_action()
	pass # Replace with function body.

func do_edit_title(card: Card, title: String) -> void:
	if visible and get_parent().visible and card.card_id == current_card.card_id:
		title_edit.text = title
	card.title = title
	pass

func undo_edit_title(card: Card, title: String) -> void:
	if visible and get_parent().visible and card.card_id == current_card.card_id:
		title_edit.text = title
	card.title = title
	pass

func description_focus_exited() -> void:
	if current_card.description != description_edit.text:
		var old_description = current_card.description
		current_card.description = description_edit.text
		undo_redo.create_action("Description Edited on card: " + current_card.title)
		undo_redo.add_do_property(current_card, "description", description_edit.text)
		undo_redo.add_undo_property(current_card, "description", old_description)
		undo_redo.add_do_method(open.bind(current_project, current_card, current_tags))
		undo_redo.add_undo_method(open.bind(current_project, current_card, current_tags))
		current_project.commit_undo_redo_action()
		open(current_project, current_card, current_tags)
#		undo_redo.add_do_method(do_edit_description.bind(current_card, description_edit.text))
#		undo_redo.add_undo_method(undo_edit_description.bind(current_card, current_card.description))
#		current_project.commit_undo_redo_action()
	pass # Replace with function body.

func do_edit_description(card: Card, description: String) -> void:
	if visible and get_parent().visible and card.card_id == current_card.card_id:
		description_edit.text = description
	card.description = description
	pass

func undo_edit_description(card: Card, description: String) -> void:
	if visible and get_parent().visible and card.card_id == current_card.card_id:
		description_edit.text = description
	card.description = description
	pass

func comment_edited(card: Card, comment: CardComment) -> void:
	undo_redo.create_action("Comment Edited on card: " + current_card.title)
	var c_index: int = comment.get_index()
	var old_comments: Array[String] = card.comments.duplicate(true)
	var new_comments: Array[String] = old_comments.duplicate(true)
	new_comments[c_index] = comment.text
	card.comments = new_comments
	undo_redo.add_do_property(current_card, "comments", new_comments)
	undo_redo.add_undo_property(current_card, "comments", old_comments)
	undo_redo.add_do_method(open.bind(current_project, current_card, current_tags))
	undo_redo.add_undo_method(open.bind(current_project, current_card, current_tags))
	current_project.commit_undo_redo_action()
	open(current_project, current_card, current_tags)
	
#	undo_redo.add_do_method(do_edit_comment.bind(card, comment, comment.text, c_index))
#	undo_redo.add_undo_method(undo_edit_comment.bind(card, comment, card.comments[c_index], c_index))
#	current_project.commit_undo_redo_action()
	pass

#func do_edit_comment(card: Card, comment: CardComment, new_comment: String, index: int) -> void:
#	if visible and get_parent().visible and is_instance_valid(comment):
#		comment.text = new_comment
#	if is_instance_valid(card):
#		card.comments[index] = new_comment
#	pass
#
#func undo_edit_comment(card: Card, comment: CardComment, old_comment: String, index: int) -> void:
#	if visible and get_parent().visible and is_instance_valid(comment):
#		comment.text = old_comment
#		pass
#	if is_instance_valid(card):
#		card.comments[index] = old_comment
#	pass

func add_comment_pressed(is_loaded: bool = false):
	var comment: CardComment = comment_prefab.instantiate() as CardComment
	
	if not is_loaded:
		var old_comments: Array[String] = current_card.comments.duplicate(true)
		var new_comments: Array[String] = old_comments.duplicate(true)
		new_comments.append("")
		undo_redo.create_action("Create Comment on card: " + current_card.title)
		current_card.comments = new_comments.duplicate(true)
		undo_redo.add_do_property(current_card, "comments", new_comments)
		undo_redo.add_undo_property(current_card, "comments", old_comments)
		undo_redo.add_do_method(open.bind(current_project, current_card, current_tags))
		undo_redo.add_undo_method(open.bind(current_project, current_card, current_tags))
		current_project.commit_undo_redo_action()
		open(current_project, current_card, current_tags)
	else:
		comment_container.add_child(comment)
		comment.delete.connect(comment_deleted.bind(current_card, comment))
		comment.edited.connect(comment_edited.bind(current_card, comment))
		return comment
	return comment
#	undo_redo.add_do_reference(comment)
#	undo_redo.add_do_method(do_create_comment.bind(current_card, comment))
#	undo_redo.add_undo_method(undo_create_comment.bind(current_card, comment))
	
	pass # Replace with function body.

#func do_create_comment(card: Card, comment: CardComment) -> void:
#	if visible and get_parent().visible and is_instance_valid(comment):
#		comment_container.add_child(comment)
#		comment.delete.connect(comment_deleted.bind(current_card, comment))
#		comment.edited.connect(comment_edited.bind(current_card, comment))
#	if is_instance_valid(card):
#		card.comments.append("")
#	pass
#
#func undo_create_comment(card: Card, comment: CardComment) -> void:
#	if visible and get_parent().visible and is_instance_valid(comment):
#		comment_container.remove_child(comment)
#		comment.delete.disconnect(comment_deleted.bind(current_card, comment))
#		comment.edited.disconnect(comment_edited.bind(current_card, comment))
#	if is_instance_valid(card):
#		card.comments.pop_back()
#	pass

func comment_deleted(card: Card, comment: HBoxContainer) -> void:
	undo_redo.create_action("Delete Comment on card: " + card.title)
	var old_comments: Array[String] = card.comments.duplicate(true)
	var new_comments: Array[String] = old_comments.duplicate(true)
	new_comments.remove_at(comment.get_index())
	card.comments = new_comments.duplicate(true)
	undo_redo.add_do_property(card, "comments", new_comments)
	undo_redo.add_undo_property(card, "comments", old_comments)
	undo_redo.add_do_method(open.bind(current_project, card, current_tags))
	undo_redo.add_undo_method(open.bind(current_project, card, current_tags))
	current_project.commit_undo_redo_action()
	open(current_project, card, current_tags)
#	undo_redo.add_undo_reference(comment)
#	undo_redo.add_do_method(do_delete_comment.bind(current_card, comment, comment.get_index()))
#	undo_redo.add_undo_method(undo_delete_comment.bind(current_card, comment, comment.get_index()))
#	undo_redo.add_do_method(comment_container.remove_child.bind(comment))
#	undo_redo.add_undo_method(comment_container.add_child.bind(comment))
#	undo_redo.add_undo_method(comment_container.move_child.bind(comment, comment.get_index()))
#	current_project.commit_undo_redo_action()
#	comment.queue_free()
	pass

#func do_delete_comment(card: Card, comment: CardComment, index: int) -> void:
#	if visible and get_parent().visible and is_instance_valid(comment):
#		comment_container.remove_child(comment)
#		pass
#	card.comments.remove_at(index)
#	pass
#
#func undo_delete_comment(card: Card, comment: CardComment, index: int) -> void:
#	if visible and get_parent().visible and is_instance_valid(comment):
#		comment_container.add_child(comment)
#		comment_container.move_child(comment, comment.get_index())
#		pass
#	card.comments.insert(index, comment.text)
#	pass

func due_date_selected(date: Date) -> void:
	var action_name_start: String = ""
	if calendar_button.text.to_lower() == "none": action_name_start = "Add"
	else: action_name_start = "Edit"
	var old_date: Date = calendar_button.current_date
	undo_redo.create_action(action_name_start + " on card: " + current_card.title)
	
	current_card.due_date = date
	undo_redo.add_do_property(current_card, "due_date", date)
	undo_redo.add_undo_property(current_card, "due_date", old_date)
	
	undo_redo.add_do_method(open.bind(current_project, current_card, current_tags))
	undo_redo.add_undo_method(open.bind(current_project, current_card, current_tags))
	current_project.commit_undo_redo_action()
	open(current_project, current_card, current_tags)
	
#	undo_redo.add_do_method(do_edit_due_date.bind(current_card, date))
#	undo_redo.add_undo_method(undo_edit_due_date.bind(current_card, old_date))
#	current_project.commit_undo_redo_action()
	pass # Replace with function body.

#func do_edit_due_date(card: Card, new_date: Date) -> void:
#	if visible and get_parent().visible:
#		calendar_button.text = new_date.date("MM-DD-YYYY")
#	card.due_date = new_date
#	pass
#
#func undo_edit_due_date(card: Card, old_date: Date) -> void:
#	if visible and get_parent().visible:
#		if is_instance_valid(old_date):
#			calendar_button.text = old_date.date("MM-DD-YYYY")
#	card.due_date = old_date
#	pass

func edit_dependancies_pressed() -> void:
	card_edit_dependancies.emit(current_card)
	pass # Replace with function body.














