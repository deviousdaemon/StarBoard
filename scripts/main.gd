extends Control

var project_prefab: PackedScene = preload("res://scenes/project.tscn") as PackedScene
var recent_projects_menu := PopupMenu.new()
var view_filter_menu := PopupMenu.new()
var view_filter_tag_menu := PopupMenu.new()
var view_filter_dependency_menu := PopupMenu.new()
#var view_filter_due_date_menu := PopupMenu.new()
var config := ConfigFile.new()
var recent_files_shortcuts: Array[Shortcut] = []

var is_quitting: bool = false
var projects_open: Array[Project] = []
var config_path: String = ""
var recent_dir: String = ""
var recent_files: Array = []
var is_saving: bool = false
var current_project_index: int = -1
var is_closing_projects: bool = false
var current_tags: Dictionary = {}

@onready var file_menu: PopupMenu = (Helper.get_descendant_in_group(self, "FileMenu") as MenuButton).get_popup() as PopupMenu
@onready var view_menu_button: MenuButton = Helper.get_descendant_in_group(self, "ViewMenu") as MenuButton as MenuButton
@onready var view_menu: PopupMenu = view_menu_button.get_popup() as PopupMenu
@onready var help_menu: PopupMenu = (Helper.get_descendant_in_group(self, "HelpMenu") as MenuButton).get_popup() as PopupMenu
@onready var input_blocker: Control = $InputBlocker as Control
@onready var tab_controller: TabController = Helper.get_descendant_of_class(self, "TabContainer") as TabController
@onready var new_project_prompt: NewProjectPrompt = Helper.get_descendant_in_group(self, "NewProjectPrompt") as NewProjectPrompt
@onready var ask_to_save_prompt: AskToSavePrompt = Helper.get_descendant_in_group(self, "AskToSavePrompt") as AskToSavePrompt
@onready var card_editor: CardEditor = Helper.get_descendant_in_group(self, "CardEditor") as CardEditor
@onready var portable_mode_prompt: Control = Helper.get_descendant_in_group(self, "MPortableModePrompt") as Control
@onready var file_dialog: MFileDialog = Helper.get_descendant_in_group(self, "MFileDialog") as MFileDialog
@onready var license_info_prompt: Control = Helper.get_descendant_in_group(self, "LicenseInfoPrompt") as Control

func _ready() -> void:
	if FileAccess.file_exists(Helper.get_executable_directory() + "sb.config"):
		config_path = Helper.get_executable_directory() + "sb.config"
	elif FileAccess.file_exists(ProjectSettings.globalize_path("user://") + "sb.config"):
		config_path = ProjectSettings.globalize_path("user://") + "sb.config"
	if config_path == "" or not FileAccess.file_exists(config_path):
		input_blocker.show()
		portable_mode_prompt.show()
	else:
		initialize_config_file()
	
	recent_projects_menu.index_pressed.connect(recent_project_button_pressed)
	file_menu.id_pressed.connect(file_menu_button_pressed)
	view_menu_button.pressed.connect(view_menu_pressed)
	view_menu.id_pressed.connect(view_menu_button_pressed)
	file_dialog.get_cancel_button().pressed.connect(file_dialog_cancel_pressed)
	ask_to_save_prompt.response_confirmed.connect(ask_to_save_prompt_response)
	help_menu.id_pressed.connect(help_menu_button_pressed)
#	create_shortcuts()
	init_file_menu()
	init_recent_files()
	init_view_menu()
	init_help_menu()
	pass

#func create_shortcuts() -> void:
#	var actions: Array[StringName] = InputMap.get_actions() as Array[StringName]
#	for i in range(0, 10, 1):
#		var shortcut := Shortcut.new()
#		shortcut.events.append_array(InputMap.action_get_events("recent_project_" + str(i)))
#		recent_files_shortcuts.append(shortcut)
#		pass
#	pass

func focus_entered() -> void:
	release_focus()
	pass # Replace with function body.

func _process(_delta: float) -> void:
	if is_closing_projects:
		if input_blocker.visible or is_saving: return
		var project: Project = null
		if projects_open.size() >= 1:
			project = projects_open.back() as Project
			tab_close_requested(project, project.get_index())
		else:
			is_closing_projects = false
			quit()
			return
		pass
	if is_quitting:
		if get_child_count() == 0:
			if is_instance_valid(Helper):
				if not Helper.is_queued_for_deletion():
					Helper.queue_free()
			else:
				await get_tree().process_frame
				await get_tree().process_frame
				await get_tree().process_frame
				await get_tree().process_frame
				await get_tree().process_frame
#				print(true)
#				print_orphan_nodes()
				queue_free()
				get_tree().quit()
				pass
	pass

func _input(event: InputEvent) -> void:
	if get_viewport().gui_get_focus_owner() != null: return
	if is_instance_valid(input_blocker):
		if input_blocker.visible: return
	if event.is_action_released("quit"): quit_pressed()
	if event.is_action_released("new_project", true):
		new_project_pressed()
	if event.is_action_released("open_project", true): 
		open_project_pressed()
		pass
	if event.is_action_released("save_project", true):
		save_project_pressed()
		pass
	if event.is_action_released("save_project_as", true):
		# TODO Save Project As
		pass
	if event is InputEventKey:
		for i in range(0, 10, 1):
			if i >= recent_files.size(): continue
			if event.is_action_released("recent_project_" + str(i + 1)):
				file_dialog_file_selected(recent_files[i])
				pass
		pass
	pass

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			quit_pressed()

func init_file_menu() -> void:
	file_menu.add_item("New Project")
	file_menu.add_item("Open Project")
	recent_projects_menu.name = "recent_projects"
	file_menu.add_child(recent_projects_menu)
	file_menu.add_submenu_item("Recent Projects", "recent_projects")
	file_menu.set_item_disabled(2, true)
	file_menu.add_item("Save Project")
	file_menu.set_item_disabled(3, true)
	file_menu.add_item("Save Project As...")
	file_menu.set_item_disabled(4, true)
	file_menu.add_item("Quit")
	pass

func init_view_menu() -> void:
	view_filter_menu.name = "view_filter"
	view_menu.add_child(view_filter_menu)
	view_menu.add_submenu_item("Filter View", "view_filter")
	
	view_filter_tag_menu.name = "filter_tag"
	view_filter_dependency_menu.name = "filter_dependency"
#	view_filter_due_date_menu.name = "filter_due_date"
	
	view_filter_menu.add_child(view_filter_tag_menu)
	view_filter_menu.add_submenu_item("Tag", "filter_tag")
	view_filter_menu.add_child(view_filter_dependency_menu)
	view_filter_menu.add_submenu_item("Dependency", "filter_dependency")
#	view_filter_menu.add_child(view_filter_due_date_menu)
#	view_filter_menu.add_submenu_item("Due Date", "filter_due_date")
	
	view_filter_tag_menu.id_pressed.connect(filter_view_button_pressed.bind(0))
	view_filter_dependency_menu.id_pressed.connect(filter_view_button_pressed.bind(1))
#	view_filter_due_date_menu.id_pressed.connect(filter_view_button_pressed.bind(2))
	
	
	view_menu.add_item("Reset View")
	
#	view_filter_menu.add_item("By Tag")
#	view_filter_menu.add_item("By Dependency")
#	view_filter_menu.add_item("By Due Date")
#
#	view_filter_menu.id_pressed.connect(filter_view_button_pressed)
	pass

func init_help_menu() -> void:
	help_menu.add_item("License Information")
	pass

func init_recent_files() -> void:
	recent_projects_menu.clear()
	var file_list: Array = recent_files.duplicate(true)
	if file_list.size() > 10: file_list.resize(10)
	for i in file_list:
#		var file := FileAccess.open(i, FileAccess.WRITE_READ)
#		var data: Dictionary = str_to_var(file.get_as_text())
		
		var path: String = i.get_file()
		var id: int = recent_projects_menu.item_count
		recent_projects_menu.add_item(path)
		recent_projects_menu.set_item_metadata(id, i)
#		recent_projects_menu.set_item_shortcut(id, recent_files_shortcuts[i])
		pass
	if recent_projects_menu.item_count > 0:
		file_menu.set_item_disabled(2, false)
	else:
		file_menu.set_item_disabled(2, true)
	pass

func recent_project_button_pressed(index: int) -> void:
	var path: String = recent_projects_menu.get_item_metadata(index)
	file_dialog_file_selected(path)
	pass

func save_config_before_quitting() -> void:
	var err: int = config.load(config_path)
	if err == ERR_FILE_NOT_FOUND: return
#		if not config.has_section_key("app", "recent_files"):
#			config.set_value("app", "recent_files", [])
#		if not config.has_section_key("app", "recent_dir"):
#			config.set_value("app", "recent_dir", "")
	elif config.load(config_path) == OK:
		config.set_value("app", "display_index", DisplayServer.window_get_current_screen())
		if get_window().mode == Window.MODE_MAXIMIZED:
			config.set_value("app", "window_maximized", true)
		else:
			config.set_value("app", "last_window_size", get_window().size)
			config.set_value("app", "last_window_position", get_window().position)
		
	config.save(config_path)
	pass

func quit_pressed() -> void:
	if quit_check():
		quit()
	pass

func quit() -> void:
	save_config_before_quitting()
	is_quitting = true
	
	card_editor.delete()
	
	for i in get_children():
		if i.has_method("close_project"):
			i.close_project()
		i.propagate_call("queue_free")
		i.queue_free()
	pass

func quit_check() -> bool:
	if not projects_open.is_empty():
		for i in projects_open:
			if i.modified:
				is_closing_projects = true
				break
		if is_closing_projects: return false
	return true

func file_menu_button_pressed(button_id: int) -> void:
	match button_id:
		0: #New Project
			new_project_pressed()
			pass
		1: # Open Project
			open_project_pressed()
			pass
		2: # Recent Projects
			
			pass
		3: # Save Project
			save_project_pressed()
			pass
		4: # Save Project As
			
			pass
		5: # Quit
			quit_pressed()
			pass
	pass

func view_menu_button_pressed(button_id: int) -> void:
	match button_id:
		0: #View filter
			pass
		1: # Reset View
			clear_view_filter()
			pass
	pass

func view_menu_pressed() -> void:
	var max_characters: int = 32
	view_filter_tag_menu.clear()
#	view_filter_due_date_menu.clear()
	view_filter_dependency_menu.clear()
	view_filter_menu.set_item_disabled(0, true)
	view_filter_menu.set_item_disabled(1, true)
	if projects_open.is_empty(): return
#	match button_id:
#		0: # Filter View
	# Populate Sub Menus
	var project: Project = projects_open[tab_controller.current_tab] as Project
	var tags: Dictionary = project.tags.duplicate(true)
#	var due_dates: Dictionary = project.get_due_dates()
	var dependencies: Dictionary = project.get_dependencies()
	
	if not tags.is_empty():
		view_filter_menu.set_item_disabled(0, false)
		var keys: Array = tags.keys()
		for i in keys.size():
			var tag: String = keys[i]
			var cards: Array = tags[tag]
			view_filter_tag_menu.add_item(tag.capitalize(), i)
			view_filter_tag_menu.set_item_metadata(i, cards)
	if not dependencies.is_empty():
		view_filter_menu.set_item_disabled(1, false)
		var keys: Array = dependencies.keys()
		for i in keys.size():
			var d_card: Card = project.get_card_by_id(int(keys[i]))
			var o_cards: Array = dependencies[keys[i]]
			var title: String = d_card.get_title()
			if title.length() > max_characters:
				title = title.substr(0, max_characters - 3) + "..."
			view_filter_dependency_menu.add_item(title, i)
			view_filter_dependency_menu.set_item_metadata(i, o_cards)
			pass
#			if not due_dates.is_empty():
#
#				pass
	pass

func filter_view_button_pressed(button_id: int, filter_type: int) -> void:
	clear_view_filter()
	var project: Project = projects_open[current_project_index]
	match filter_type:
		0: # Tag
#			var tag: String = view_filter_tag_menu.get_item_text(button_id)
			var cards: Array = view_filter_tag_menu.get_item_metadata(button_id)
			for i in project.get_cards():
				if not cards.has(i): i.hide()
				pass
			pass
		1: # Dependency
			var cards: Array = view_filter_tag_menu.get_item_metadata(button_id)
			for i in project.get_cards():
				if not cards.has(i): i.hide()
				pass
			pass
#		2: # Due Date
#			var tag: String = view_filter_tag_menu.get_item_text(button_id)
#			var cards: Array[Card] = view_filter_tag_menu.get_item_metadata(button_id)
#			pass
	pass

func clear_view_filter() -> void:
	if projects_open.is_empty(): return
	if current_project_index >= projects_open.size(): return
	var project: Project = projects_open[current_project_index]
	for i in project.get_cards():
		i.visible = true
		pass
	pass

func open_project_pressed() -> void:
	if recent_dir == "":
		recent_dir = Helper.get_executable_directory()
	file_dialog.open(FileDialog.FILE_MODE_OPEN_FILE, recent_dir)
	pass

func save_project_pressed() -> void:
	var c_project: Project = tab_controller.get_child(tab_controller.current_tab) as Project
	
	if not c_project.modified: return
	
	is_saving = true
	
	if c_project.project_path != "":
		file_dialog_file_selected(c_project.project_path)
		return
	
	if recent_dir == "":
		recent_dir = Helper.get_executable_directory()
	file_dialog.open(FileDialog.FILE_MODE_SAVE_FILE, recent_dir)
	pass

func new_project_pressed() -> void:
	new_project_prompt.open()
	pass

func create_project(title: String, is_loaded: bool = false) -> Project:
	if title == "" and not is_loaded: title = generate_project_name()
	
	var new_project: Project = project_prefab.instantiate() as Project
	new_project.card_editor = card_editor
	new_project.title = title
	
	tab_controller.add_tab(new_project, title)
	
	new_project.open_card.connect(card_editor.open)
	new_project.modified_state_changed.connect(project_modified_state_changed.bind(new_project))
	card_editor.card_tag_removed.connect(new_project.card_tag_removed)
	card_editor.card_tag_updated.connect(new_project.card_tag_updated)
	card_editor.card_tag_added.connect(new_project.card_tag_added)
	card_editor.card_edit_dependancies.connect(new_project.card_edit_dependancies)
	
	#card_tag_removed(card, tag)
	#card_tag_updated(old_tag, new_tag)
	
	file_menu.set_item_disabled(3, false)
	
	projects_open.append(new_project)
	current_project_index = projects_open.size() - 1
	tab_controller.current_tab = current_project_index
	
	clear_view_filter()
	
	return new_project

func project_modified_state_changed(is_modified: bool, project: Project) -> void:
	tab_controller.tab_set_modified(project.get_index(), is_modified)
	pass

func generate_project_name() -> String:
	var p_name: String = "MyProject"
	var name_is_ok: bool = false
	while not name_is_ok:
		name_is_ok = true
		for i in tab_controller.get_tab_count():
			if tab_controller.get_tab_title(i) == p_name:
				name_is_ok = false
				if p_name == "MyProject":
					p_name = "MyProject0"
					break
				else:
					p_name = "MyProject" + str(p_name.replace("MyProject", "").to_int() + 1)
					break
		pass
	
	return p_name

func tab_changed(tab: int) -> void:
	current_project_index = tab
	clear_view_filter()
	pass # Replace with function body.

func tab_close_requested(project: Project, tab_idx: int, force: bool = false) -> void:
	if not project.modified or force:
		tab_controller.close_tab(tab_idx)
		projects_open.remove_at(tab_idx)
	else:
		tab_controller.current_tab = tab_idx
		ask_to_save_prompt.open(project, tab_idx)
		pass
	pass # Replace with function body.

func run_portable_pressed() -> void:
	input_blocker.hide()
	portable_mode_prompt.hide()
	config_path = Helper.get_executable_directory() + "sb.config"
	initialize_config_file()
	pass # Replace with function body.

func run_standard_pressed() -> void:
	input_blocker.hide()
	portable_mode_prompt.hide()
	config_path = ProjectSettings.globalize_path("user://") + "sb.config"
	initialize_config_file()
	pass # Replace with function body.

func initialize_config_file() -> void:
	var err: int = config.load(config_path)
	if err == ERR_FILE_NOT_FOUND:
		if not config.has_section_key("app", "recent_files"):
			config.set_value("app", "recent_files", [])
		if not config.has_section_key("app", "recent_dir"):
			config.set_value("app", "recent_dir", "")
		if not config.has_section_key("app", "last_window_size"):
			config.set_value("app", "last_window_size", Vector2i(1280, 720))
		if not config.has_section_key("app", "last_window_position"):
			config.set_value("app", "last_window_position", (DisplayServer.screen_get_size() - Vector2i(1280, 720)) / 2)
		if not config.has_section_key("app", "window_maximized"):
			config.set_value("app", "window_maximized", false)
		if not config.has_section_key("app", "display_index"):
			config.set_value("app", "display_index", DisplayServer.window_get_current_screen())
	elif config.load(config_path) == OK:
		recent_files = config.get_value("app", "recent_files", [])
		recent_dir = config.get_value("app", "recent_dir", "")
		get_window().current_screen = config.get_value("app", "display_index", DisplayServer.window_get_current_screen())
		if config.get_value("app", "window_maximized", false):
			get_window().mode = Window.MODE_MAXIMIZED
		else:
			get_window().size = config.get_value("app", "last_window_size", Vector2i(1280, 720))
			get_window().position = config.get_value("app", "last_window_position", (DisplayServer.screen_get_size() - Vector2i(1280, 720)) / 2)
		
	config.save(config_path)
	pass

func file_dialog_cancel_pressed() -> void:
	if is_closing_projects: is_closing_projects = false
	pass

func help_menu_button_pressed(button_id: int) -> void:
	match button_id:
		0: # License Information
			license_info_prompt.open()
			pass
	pass

func file_dialog_file_selected(path: String = "") -> void:
	if path == "":
		is_saving = false
		return
	if is_saving:
		var c_project: Project = tab_controller.get_child(tab_controller.current_tab) as Project
		var p_data: Dictionary = c_project.get_project_data()
		var data_string: String = var_to_str(p_data)
		var file := FileAccess.open(path, FileAccess.WRITE_READ)
		if file.get_error() == OK:
			
			file.store_string(data_string)
			if !recent_files.has(path):
				recent_files.append(path)
			c_project.set_modified(false)
		is_saving = false
	else:
		var file := FileAccess.open(path, FileAccess.READ)
		if file.get_error() == OK:
			var p_data: Dictionary = str_to_var(file.get_as_text())
			assert(p_data.has("title"), "Project Data is Invalid!")
			var project: Project = create_project(p_data.title)
			project.project_path = path
			project.load_data(p_data)
			if !recent_files.has(path):
				recent_files.append(path)
			pass
#		
		pass
	recent_dir = path.replace(path.get_file(), "")
	if config.load(config_path) == OK:
		config.set_value("app", "recent_dir", recent_dir)
		config.set_value("app", "recent_files", recent_files)
		config.save(config_path)
		pass
	pass # Replace with function body.

func ask_to_save_prompt_response(response: int, project: Project, tab_index: int) -> void:
	match response:
		0: # Save
			save_project_pressed()
			tab_close_requested(project, tab_index)
			pass
		1: # Discard
			tab_close_requested(project, tab_index, true)
			pass
		2: # Cancel
			is_closing_projects = false
			pass
	pass



















