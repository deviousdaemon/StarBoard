extends LineEdit

func _input(event: InputEvent) -> void:
	if not has_focus(): return
	if event.is_action_released("ui_accept") or event.is_action_released("ui_cancel"): release_focus()
	pass
