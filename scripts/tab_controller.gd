extends TabContainer
class_name TabController

signal tab_close_requested(project, tab_idx)

var modified_icon: CompressedTexture2D = preload("res://icons/stardusk/icon_modified_16px.png") as CompressedTexture2D

var tabbar: TabBar = null

func _ready() -> void:
	_get_tabbar()
	pass

func _get_tabbar() -> void:
	await get_parent().ready
	tabbar = Helper.get_descendant_of_class(self, "TabBar") as TabBar
	tabbar.tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_ALWAYS
	tabbar.connect("tab_close_pressed", tab_close_pressed)
	pass

func tab_set_modified(tab_idx: int, is_modified: bool) -> void:
	if tab_idx >= get_tab_count(): return
	set_tab_icon(tab_idx, modified_icon if is_modified else null)
	pass

func add_tab(node: Node, title: String) -> void:
	var tab_idx: int = get_tab_count()
	add_child(node)
	set_tab_title(tab_idx, title)
	current_tab = tab_idx
	pass

func tab_close_pressed(tab_idx: int) -> void:
	emit_signal("tab_close_requested", get_child(tab_idx, false), tab_idx)
	pass

func close_tab(tab_idx: int) -> void:
	get_child(tab_idx, false).close_project()
	get_child(tab_idx, false).queue_free()
	pass
