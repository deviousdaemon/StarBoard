extends FileDialog
class_name MFileDialog

const MODES: Dictionary = {
	SAVE=0,
	LOAD=1
}

#var directory := DirAccess.new()

func _ready() -> void:
	get_tree().root.size_changed.connect(window_size_changed)
	window_size_changed()
	pass

func window_size_changed() -> void:
	await get_tree().process_frame
	var w_size: Vector2 = get_tree().root.size
	min_size = w_size * 0.65
	max_size = w_size - Vector2(16, 16)
	size.clamp(min_size, max_size)
	if visible: popup_centered(min_size)
	pass

func open(_file_mode: int, dir: String = "") -> void:
	file_mode = _file_mode
	if dir != "":
		var dir_access := DirAccess.open(dir)
		if dir_access.get_open_error() == OK:
			current_dir = dir
		pass
	visible = true
	window_size_changed()
	pass
