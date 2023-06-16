extends PanelContainer
class_name Board

signal open_card(card)
signal card_drag_request(card)
signal request_card_id

var card_prefab: PackedScene = preload("res://scenes/card.tscn") as PackedScene

var project: Project = null : set = set_project
var undo_redo: UndoRedo = null
var board_id: int = -1

@onready var card_container: VBoxContainer = Helper.get_descendant_in_group(self, "CardContainer") as VBoxContainer

func load_data(data: Dictionary) -> void:
	assert(data.has("board_id"), "Board Data Invalid!")
	board_id = data.board_id
	if data.has("cards"): for i in data.cards:
		var card: Card = create_card(true) as Card
		card.load_data(i)
	pass

func get_board_data() -> Dictionary:
	var b_data: Dictionary = {
		board_id=board_id,
		cards=[]
	}
	for i in card_container.get_children():
		b_data.cards.append(i.get_card_data())
	return b_data

func set_project(pjct: Project) -> void:
	project = pjct
	undo_redo = project.undo_redo
	pass

func create_card(is_loaded: bool = false) -> Card:
	undo_redo.create_action("Create Card")
	var card: Card = card_prefab.instantiate() as Card
	if not is_loaded:
		undo_redo.add_do_reference(card)
		card.parent_board_id = board_id
		undo_redo.add_do_property(card, "parent_board_id", board_id)
#		card.open_card.connect(card_opened)
		undo_redo.add_do_method(card.connect.bind("open_card", card_opened))
		undo_redo.add_undo_method(card.disconnect.bind("open_card", card_opened))
#		card.card_drag_request.connect(card_drag_requested)
		undo_redo.add_do_method(card.connect.bind("card_drag_request", card_drag_requested))
		undo_redo.add_undo_method(card.disconnect.bind("card_drag_request", card_drag_requested))
#	if not is_loaded:
		var card_id: int = project.request_card_id()
		card.card_id = card_id
		undo_redo.add_do_property(card, "card_id", card_id)
		card.card_index = card_container.get_child_count()
		undo_redo.add_do_property(card, "card_index", card_container.get_child_count())
	
		undo_redo.add_do_method(card_container.add_child.bind(card))
		undo_redo.add_undo_method(card_container.remove_child.bind(card))
#		card_container.add_child(card)
		project.commit_undo_redo_action()
	else:
		
		card.open_card.connect(card_opened)
		card.card_drag_request.connect(card_drag_requested)
		card.parent_board_id = board_id
		card.card_index = card_container.get_child_count()
		card_container.add_child(card)
		pass
	return card

func update_cards() -> void:
	await get_tree().process_frame
	for i in card_container.get_children():
		if i is Card:
			i.card_index = i.get_index()
			i.parent_board_id = board_id
	pass

func get_cards() -> Array[Card]:
	var cards: Array[Card] = []
	for i in card_container.get_children(true):
		if i.has_method("ID_CARD"): cards.append(i)
	return cards

func reparent_card(old_board: Board, card: Card, index: int = -1) -> void:
	undo_redo.create_action("Move Card")
	
	
	card.parent_board_id = board_id
	undo_redo.add_do_property(card, "parent_board_id", board_id)
	undo_redo.add_undo_property(card, "parent_board_id", card.parent_board_id)
	card.orphan_self()
	undo_redo.add_do_method(card.orphan_self)
	if old_board.board_id != board_id:
		old_board.update_cards()
		undo_redo.add_do_method(old_board.update_cards)
	
	undo_redo.add_undo_method(card.orphan_self)
	undo_redo.add_undo_method(old_board.card_container.add_child.bind(card))
	card_container.add_child(card)
	undo_redo.add_do_method(card_container.add_child.bind(card))
	
	if index == -1:
		card.card_index = card_container.get_child_count() - 1
		undo_redo.add_do_property(card, "card_index", card_container.get_child_count() - 1)
		undo_redo.add_undo_property(card, "card_index", card.card_index)
	else:
		card_container.move_child(card, index)
		undo_redo.add_do_method(card_container.move_child.bind(card, index))
		undo_redo.add_undo_method(card_container.move_child.bind(card, card.card_index))
#		card.card_index = card.get_index()
		
		undo_redo.add_do_property(card, "card_index", card.get_index())
		undo_redo.add_undo_property(card, "card_index", card.card_index)
		pass
		
	update_cards()
	if old_board.board_id != board_id:
		undo_redo.add_undo_method(old_board.update_cards)
	undo_redo.add_do_method(update_cards)
	undo_redo.add_undo_method(update_cards)
	
	
	project.commit_undo_redo_action()
	
	
	pass

func card_opened(card: Card) -> void:
	emit_signal("open_card", card)

func card_drag_requested(card: Card) -> void:
	card_drag_request.emit(card)







