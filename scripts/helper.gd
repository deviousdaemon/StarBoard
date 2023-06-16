extends Node

var exec_dir: String = ""

func _init():
	if is_running_in_editor(): exec_dir = ProjectSettings.globalize_path("res://")
	else: exec_dir = OS.get_executable_path().get_base_dir() + "/"
	pass

func get_executable_directory() -> String: return exec_dir

func is_running_in_editor() -> bool:
	return OS.has_feature("editor")

func is_running_in_debug() -> bool:
	return OS.has_feature("debug")

func get_descendant_of_class(_parent: Node, _class: String) -> Node:
	var d: Array = get_descendants_of_class(_parent, _class)
	if d.is_empty(): return null
	return d[0]

func get_descendants_of_class(_parent: Node, _class: String) -> Array[Node]:
	var nodes: Array[Node] = []
	
	for i in _parent.get_children(true):
		if i.is_class(_class):
			nodes.append(i)
		if i.get_child_count() > 0:
			var new_nodes: Array = _get_descendants_of_class(i, _class)
			if new_nodes != null:
				if not new_nodes.is_empty():
					nodes.append_array(new_nodes)
	return nodes

func _get_descendants_of_class(_parent: Node, _class: String) -> Array[Node]:
	var nodes: Array[Node] = []
	for i in _parent.get_children(true):
		if i.is_class(_class):
			nodes.append(i)
		if i.get_child_count() > 0:
			var new_nodes: Array[Node] = _get_descendants_of_class(i, _class)
			if not new_nodes.is_empty():
				nodes.append_array(new_nodes)
	return nodes


func get_descendant_in_group(calling_node: Node, group: String) -> Node:
	var objects: Array[Node] = get_tree().get_nodes_in_group(group)
	if !objects.is_empty():
		for i in objects:
			if calling_node.is_ancestor_of(i):
				return i
	
	return null

func get_descendants_in_group(calling_node: Node, group: String) -> Array[Node]:
	
	var nodes: Array[Node] = []
	var objects: Array[Node] = get_tree().get_nodes_in_group(group)
	if !objects.is_empty():
		for i in objects:
			if calling_node.is_ancestor_of(i):
				nodes.append(i)
	
	return nodes

func is_mouse_hovering(area:Vector2, mouse_pos:Vector2, tolerance:float=0.0) -> bool:
	if mouse_pos.x >= 0 - tolerance && mouse_pos.y >= 0 - tolerance:
		if mouse_pos.x < area.x + tolerance && mouse_pos.y < area.y + tolerance:
			return true
	return false

func is_mouse_hovering_control(control: Control, tolerance:float=0.0) -> bool:
	return is_mouse_hovering(control.size, control.get_local_mouse_position(), tolerance)





































