extends PanelContainer
class_name Project

signal open_card(this, card, tags)
signal toggle_dependancy(card)
signal modified_state_changed(modified)
signal tags_modified(tags)

var board_prefab: PackedScene = load("res://scenes/board.tscn") as PackedScene


var title: String = ""
var board_counter: int = -1
var card_counter: int = -1
var tags: Dictionary = {}
var boards: Array[Board] = []
var card_editor: CardEditor = null
var project_path: String = ""

var modified: bool = false #TODO UndoRedo for Modified States
var dragged_card: Card = null
var card_selecting_dependancies: Card = null
var drag_preview := Control.new()
var undo_redo := UndoRedo.new()

@onready var board_container: HBoxContainer = Helper.get_descendant_in_group(self, "BoardContainer") as HBoxContainer
@onready var drag_container: Control = Helper.get_descendant_in_group(self, "PDragContainer") as Control
@onready var action_label: ActionLabel = Helper.get_descendant_in_group(self, "ProjectActionLabel") as ActionLabel
@onready var editing_dependancies_panel: Control = Helper.get_descendant_in_group(self, "PEditingDependanciesPanel") as Control

func _ready() -> void:
	drag_preview.mouse_filter = MOUSE_FILTER_IGNORE
	pass

func close_project() -> void:
	if undo_redo.has_redo() or undo_redo.has_undo():
		undo_redo.clear_history()
	undo_redo.free()
	pass

func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if not visible: return
	if not get_parent().visible: return
	
	if is_instance_valid(card_selecting_dependancies) and card_selecting_dependancies != null:
		if event.is_action_released("ui_cancel"):
			stop_editing_dependancies_pressed()
			pass
		pass
	
	if event.is_action_released("ui_undo", true) and undo_redo.has_undo():
		var index: int = undo_redo.get_history_count() - 1
		action_label.display_action("Undo " + undo_redo.get_action_name(index))
		undo_redo.undo()
	if event.is_action_released("ui_redo", true) and undo_redo.has_redo():
		var index: int = undo_redo.get_history_count() - 1
		action_label.display_action("Redo " + undo_redo.get_action_name(index))
		undo_redo.redo()
		pass
	if not event is InputEventMouse: return
	if is_instance_valid(dragged_card) and dragged_card != null:
		if Input.is_action_just_released("mouse_left"):
			dragged_card.dragging = false
			
			var has_parented: bool = false
			for i in boards: if Helper.is_mouse_hovering_control(i):
				var cards: Array[Card] = i.get_cards() as Array[Card]
				if cards.size() > 0:
					for j in cards.size():
						var card: Card = cards[j] as Card
						if get_global_mouse_position().y < card.global_position.y + (card.get_global_rect().size.y / 2):
#							card.card_index = card.card_index
							i.reparent_card(get_board_by_id(dragged_card.parent_board_id), dragged_card, card.card_index)
							has_parented = true
							break
						if j == cards.size() - 1:
							if get_global_mouse_position().y >= card.global_position.y + (card.get_global_rect().size.y / 2):
								i.reparent_card(get_board_by_id(dragged_card.parent_board_id), dragged_card, card.card_index + 1)
								has_parented = true
								break
				else:
					if i.board_id == dragged_card.parent_board_id:
						i.reparent_card(get_board_by_id(dragged_card.parent_board_id), dragged_card, dragged_card.card_index)
						has_parented = true
					else:
						i.reparent_card(get_board_by_id(dragged_card.parent_board_id), dragged_card)
						has_parented = true
			
			
			if not has_parented:
				var board: Board = get_board_by_id(dragged_card.parent_board_id) as Board
				board.reparent_card(get_board_by_id(dragged_card.parent_board_id), dragged_card, dragged_card.card_index)
			if is_instance_valid(drag_preview.get_parent()) and drag_preview.get_parent() != null:
				drag_preview.get_parent().remove_child(drag_preview)
			dragged_card = null
		elif Input.is_action_pressed("mouse_left"):
			dragged_card.lerp_position = get_local_mouse_position() - (dragged_card.size / 2)
			var drag_preview_has_position: bool = false
			for i in boards: if Helper.is_mouse_hovering_control(i):
				var cards: Array[Card] = i.get_cards() as Array[Card]
				if cards.size() > 0:
					for j in cards.size():
						var card: Card = cards[j] as Card
						if get_global_mouse_position().y < card.global_position.y + (card.get_global_rect().size.y / 2):
							place_drag_preview(card, i, false)
							drag_preview_has_position = true
							break
						if j == cards.size() - 1:
							if get_global_mouse_position().y >= card.global_position.y + (card.get_global_rect().size.y / 2):
								place_drag_preview(card, i, true)
								drag_preview_has_position = true
								break
						else: continue
					if drag_preview_has_position: break
				else:
					place_drag_preview(null, i)
					drag_preview_has_position = true
					break
				if drag_preview_has_position: break
			if not drag_preview_has_position:
				if is_instance_valid(drag_preview.get_parent()) and drag_preview.get_parent() != null:
					drag_preview.get_parent().remove_child(drag_preview)
#			 = get_local_mouse_position() - (dragged_card.size / 2)
			pass
		pass
	pass

func place_drag_preview(card: Card, board: Board, below: bool = false) -> void:
	if not drag_preview.is_ancestor_of(board):
		if is_instance_valid(drag_preview.get_parent()) and drag_preview.get_parent() != null:
			drag_preview.get_parent().remove_child(drag_preview)
		board.card_container.add_child(drag_preview)
	if card != null and is_instance_valid(card):
		if below:
			var val: int = clampi(card.get_index() + 1, 0, board.card_container.get_child_count() - 1)
			if drag_preview.get_index() != val:
				board.card_container.move_child(drag_preview, val)
#				print(board.card_container.get_child_count() - 1, ", ", drag_preview.get_index())
#				print(card.title)
		else:
			if drag_preview.get_index() != card.get_index():
				board.card_container.move_child(drag_preview, card.get_index())
		pass
	await get_tree().process_frame
	pass

func load_data(data: Dictionary) -> void:
	if data.has("title"): title = data.title
	if data.has("board_counter"): board_counter = data.board_counter
	if data.has("card_counter"): card_counter = data.card_counter
	if data.has("boards"): for i in data.boards:
		var board: Board = create_board(true) as Board
		board.load_data(i)
	
	if data.has("tags"):
		for i in data.tags.keys():
			tags[i] = []
			for j in data.tags[i]:
				var card: Card = get_card_by_id(j) as Card
				if not is_instance_valid(card): continue
				tags[i].append(card)
#	for i in get_cards(): update_cards_tags(i)
	pass

func get_project_data() -> Dictionary:
	var p_data: Dictionary = {
		title=title,
		board_counter=board_counter,
		card_counter=card_counter,
		boards=[],
		tags={}
	}
	for i in board_container.get_children():
		p_data.boards.append(i.get_board_data())
	for i in tags.keys():
		p_data.tags[i] = []
		for j in tags[i]:
			p_data.tags[i].append(j.card_id)
	return p_data

func get_board_ids() -> Array[int]:
	var board_ids: Array[int] = []
	for i in boards: board_ids.append(i.board_id)
	return board_ids

func get_board_by_id(board_id: int) -> Board:
	for board in boards:
		if board.board_id == board_id: return board
	return null

func get_cards() -> Array[Card]:
	var cards: Array[Card] = []
	for i in boards:
		cards.append_array(i.get_cards())
	return cards

func get_card_by_id(card_id: int) -> Card:
	for card in get_cards():
		if card.card_id == card_id: return card
	return null

func create_board(is_loaded: bool = false) -> Board:
	var board: Board = board_prefab.instantiate() as Board
	if not is_loaded:
		undo_redo.create_action("Create Board")
		undo_redo.add_do_reference(board)
		board.project = self
		undo_redo.add_do_property(board, "project", self)
		board.board_id = request_board_id()
		undo_redo.add_do_property(board, "board_id", request_board_id())
#		board.open_card.connect(card_opened)
		undo_redo.add_do_method(board.connect.bind("open_card", card_opened))
		undo_redo.add_undo_method(board.disconnect.bind("open_card", card_opened))
#		board.card_drag_request.connect(card_drag_requested)
		undo_redo.add_do_method(board.connect.bind("card_drag_request", card_drag_requested))
		undo_redo.add_undo_method(board.disconnect.bind("card_drag_request", card_drag_requested))
#		board_container.add_child(board)
		undo_redo.add_do_method(board_container.add_child.bind(board))
		undo_redo.add_undo_method(board_container.remove_child.bind(board))
		var n_boards: Array[Board] = boards.duplicate()
		n_boards.append(board)
		undo_redo.add_do_property(self, "boards", n_boards.duplicate())
		undo_redo.add_undo_property(self, "board", boards.duplicate())
		boards = n_boards
		commit_undo_redo_action()
	else:
		board.project = self
		board.open_card.connect(card_opened)
		board.card_drag_request.connect(card_drag_requested)
		board_container.add_child(board)
		boards.append(board)
		
		pass
	return board

func card_opened(card: Card) -> void:
	if is_instance_valid(card_selecting_dependancies) and card_selecting_dependancies != null:
		undo_redo.create_action("Dependancy added on card " + card_selecting_dependancies.title)
		var old_dependancies: Array[int] = card_selecting_dependancies.dependencies.duplicate(true)
		var new_dependancies: Array[int] = old_dependancies.duplicate(true)
		if new_dependancies.has(card.card_id):
			card.marked_dependancy = false
			new_dependancies.erase(card.card_id)
		else:
			card.marked_dependancy = true
			new_dependancies.append(card.card_id)
		undo_redo.add_do_method(do_update_card_dependancies.bind(card_selecting_dependancies, card, new_dependancies))
		undo_redo.add_undo_method(undo_update_card_dependancies.bind(card_selecting_dependancies, card, old_dependancies))
		commit_undo_redo_action()
		do_update_card_dependancies(card_selecting_dependancies, card, new_dependancies)

	else:
		emit_signal("open_card", self, card, tags)
	pass

func do_update_card_dependancies(card: Card, dep_card: Card, new_dependancies: Array[int]) -> void:
#	print(new_dependancies)
	if card_editor.visible:
		if new_dependancies.has(dep_card.card_id):
			card.marked_dependancy = true
		else:
			card.marked_dependancy = false
		pass
	card.dependencies = new_dependancies
	pass

func undo_update_card_dependancies(card: Card, dep_card: Card, old_dependancies: Array[int]) -> void:
	if card_editor.visible:
		if old_dependancies.has(dep_card.card_id):
			card.marked_dependancy = true
		else:
			card.marked_dependancy = false
		pass
	card.dependencies = old_dependancies
	pass

func card_drag_requested(card: Card) -> void:
	if is_instance_valid(card_selecting_dependancies) and card_selecting_dependancies != null:
		
		pass
	else:
		dragged_card = card
		card.dragging = true
		card.pressed = false
		card.get_parent().remove_child(card)
		drag_container.add_child(card)
		drag_preview.custom_minimum_size = card.size
		dragged_card.lerp_position = get_local_mouse_position() - (dragged_card.size / 2)
	pass

func commit_undo_redo_action() -> void:
	undo_redo.add_do_method(set_modified.bind(true))
	undo_redo.add_undo_method(set_modified.bind(modified))
	set_modified(true)
#	undo_redo.add_do_property(self, "modified", true)
#	undo_redo.add_undo_property(self, "modified", modified)
	undo_redo.commit_action(true)
	pass

func set_modified(is_modified: bool) -> void:
	modified = is_modified
	modified_state_changed.emit(is_modified)
	pass

func request_board_id() -> int:
	board_counter += 1
	return board_counter - 1

func request_card_id() -> int:
	card_counter += 1
	return card_counter - 1

func card_tag_added(card: Card, tag: String) -> void:
	undo_redo.create_action(tag + " Tag added to card " + card.title)
	var old_tags: Dictionary = tags.duplicate(true)
	var new_tags: Dictionary = old_tags.duplicate(true)
	if not new_tags.has(tag): new_tags[tag] = [card]
	else:
		if not new_tags[tag].has(card): new_tags[tag].append(card)
		pass
	undo_redo.add_do_property(self, "tags", new_tags)
	undo_redo.add_undo_property(self, "tags", old_tags)
	undo_redo.add_do_property(card_editor, "current_tags", new_tags)
	undo_redo.add_undo_property(card_editor, "current_tags", old_tags)
	
	
	tags = new_tags
	card_editor.current_tags = new_tags
	update_cards_tags(card)
	tags_modified.emit(tags)
	pass

func card_tag_updated(card: Card, old_tag: String, new_tag) -> void:
	undo_redo.create_action("Tag Updated from " + old_tag + " to " + new_tag + " on card " + card.title)
	var old_tags: Dictionary = tags.duplicate(true)
	var new_tags: Dictionary = tags.duplicate(true)
	
	var card_list: Array[Card] = []
	if old_tag != "" and new_tags.has(old_tag):
		card_list = new_tags[old_tag]
		if card_list.has(card): card_list.remove_at(card_list.find(card))
		if card_list.is_empty(): new_tags.erase(old_tag)
	if not new_tag == "":
		if not new_tags.has(new_tag): new_tags[new_tag] = [] as Array[Card]
		card_list = new_tags[new_tag]
		if not card_list.has(card): new_tags[new_tag].append(card)
	
	undo_redo.add_do_property(self, "tags", new_tags)
	undo_redo.add_undo_property(self, "tags", old_tags)
	undo_redo.add_do_property(card_editor, "current_tags", new_tags)
	undo_redo.add_undo_property(card_editor, "current_tags", old_tags)
	
	tags = new_tags
	card_editor.current_tags = new_tags
	update_cards_tags(card)
	tags_modified.emit(tags)
	pass

func card_tag_removed(card: Card, tag: String) -> void:
	undo_redo.create_action(tag + " tag Removed from card " + card.title)
	var old_tags: Dictionary = tags.duplicate(true)
	var new_tags: Dictionary = tags.duplicate(true)
	
	var tag_list: Array = new_tags[tag]
	if tag_list.has(card):
		tag_list.remove_at(tag_list.find(card))
		new_tags[tag] = tag_list
	if tag_list.is_empty(): new_tags.erase(tag)
	
	undo_redo.add_do_property(self, "tags", new_tags)
	undo_redo.add_undo_property(self, "tags", old_tags)
	undo_redo.add_do_property(card_editor, "current_tags", new_tags)
	undo_redo.add_undo_property(card_editor, "current_tags", old_tags)
	
	tags = new_tags
	card_editor.current_tags = new_tags
	update_cards_tags(card)
	tags_modified.emit(tags)
	pass

func update_cards_tags(card: Card) -> void:
	var c_tags: Array[String] = []
	var o_tags: Array[String] = card.tags.duplicate(true)
	for i in tags.keys():
		for j in tags[i]:
			if j.card_id == card.card_id:
				c_tags.append(i)
	
	undo_redo.add_do_property(card, "tags", c_tags)
	undo_redo.add_undo_property(card, "tags", o_tags)
	
	undo_redo.add_do_method(card_editor.open.bind(self, card, tags))
	undo_redo.add_undo_method(card_editor.open.bind(self, card, tags))
	commit_undo_redo_action()
	card.tags = c_tags
	
	card_editor.open(self, card, tags)
	pass

func card_edit_dependancies(card: Card) -> void:
	card_selecting_dependancies = card
	editing_dependancies_panel.show()
	
	
	card_editor.hide_all()
	
	card.disabled = true
	for i in card.dependencies:
		get_card_by_id(i).marked_dependancy = true
		pass
	pass

func stop_editing_dependancies_pressed() -> void:
	editing_dependancies_panel.hide()
	for i in get_cards():
		i.clear_panels()
	card_editor.open(self, card_selecting_dependancies, tags)
	card_selecting_dependancies.disabled = false
	card_selecting_dependancies = null
	pass # Replace with function body.
















