extends PanelContainer
class_name Card

signal open_card(card)
signal card_drag_request(card)

const drag_tolerance: float = 12.0

var press_position := Vector2()
var pressed: bool = false
var dragging: bool = false
var parent_board_id: int = -1
var card_index: int = -1
var lerp_position := Vector2()
var disabled: bool = false : set = set_disabled
var marked_dependancy: bool = false : set = set_marked_dependancy

var card_id: int = -1
var title: String = "" : set = _set_title, get = get_title
var description: String = ""
var complete: bool = false
var comments: Array[String] = []
var checklists: Array[Dictionary] = []
var dependencies: Array[int] = []
var tags: Array[String] = []
var due_date: Date = null

@onready var complete_icon: TextureRect = Helper.get_descendant_in_group(self, "CComplete") as TextureRect
@onready var title_label: Label = Helper.get_descendant_in_group(self, "CardTitle") as Label
@onready var disabled_panel: Panel = Helper.get_descendant_in_group(self, "CDisabledPanel") as Panel
@onready var dependancy_panel: Panel = Helper.get_descendant_in_group(self, "CDependancyPanel") as Panel

func ID_CARD() -> void:
	
	pass

func is_class(class_string: String) -> bool:
	print("true")
	if class_string == "Card": return true
	if super.is_class(class_string): return true
	return false

func set_disabled(is_disabled: bool) -> void:
	disabled = is_disabled
	disabled_panel.visible = is_disabled
	pass

func set_marked_dependancy(is_marked_dependancy: bool) -> void:
	marked_dependancy = is_marked_dependancy
	dependancy_panel.visible = is_marked_dependancy
	pass

func _process(delta: float) -> void:
	if pressed and not dragging:
		if abs((press_position - get_global_mouse_position()).length()) >= drag_tolerance:
			card_drag_request.emit(self)
		elif not Helper.is_mouse_hovering_control(self):
			pressed = false
	if dragging:
		position = lerp(position, lerp_position, 0.3)
	pass

func load_data(data: Dictionary) -> void:
	assert(data.has("card_id"), "Card Data is Corrupted; Has no card_id.")
	card_id = data.card_id
	if data.has("title"): _set_title(data.title)
	if data.has("description"): description = data.description
	if data.has("complete"): complete = data.complete
	if data.has("comments"): comments = data.comments
	if data.has("checklists"): for i in data.checklists: checklists.append(i)
	if data.has("dependencies"): dependencies = data.dependencies
	if data.has("tags"): tags = data.tags
	if data.has("due_date"): due_date = Date.new(data.due_date.day, data.due_date.month, data.due_date.year)
	pass

func orphan_self() -> void:
	get_parent().remove_child(self)
	pass

func clear_panels() -> void:
	disabled_panel.hide()
	dependancy_panel.hide()
	pass

func get_card_data() -> Dictionary:
	var card_data: Dictionary = {
		card_id = card_id,
		title = title,
		description = description,
		complete = complete,
		comments = comments.duplicate(),
		checklists =  checklists.duplicate(true),
		dependencies = dependencies.duplicate(true),
		tags = tags.duplicate(true)
		}
	if is_instance_valid(due_date):
		card_data["due_date"] = due_date.get_date_dict()
	return card_data

func button_pressed() -> void:
	if Input.is_action_just_released("mouse_left"): emit_signal("open_card", self)
	pass # Replace with function body.

func button_down() -> void:
	pressed = true
	press_position = get_global_mouse_position()
	pass # Replace with function body.

func button_up() -> void:
	pressed = false
	pass # Replace with function body.

func _set_title(new_title: String) -> void:
	title = new_title
	title_label.text = new_title
	pass

func get_title() -> String:
	return title 



























