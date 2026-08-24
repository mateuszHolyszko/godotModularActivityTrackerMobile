class_name InsertPositionInput
extends Button

signal value_changed(index: int)

@export var prompt_text: String = ""
@export var options: Array[String] = []
@export var entry_menu_scene_path: String = ""
@export var submenu_container_path: NodePath

var _options_data: Array[String] = []
var _owning_menu: Menu
var _entry_menu: Menu


func _ready() -> void:
	pressed.connect(_on_pressed)
	if _options_data.is_empty() and not options.is_empty():
		_options_data = options.duplicate()
	


func set_options_data(data: Array) -> void:
	_options_data.clear()
	for option in data:
		_options_data.append(str(option))
	


func _on_pressed() -> void:
	if _owning_menu == null:
		_owning_menu = _find_owning_menu()
	if _owning_menu == null:
		push_error("InsertPositionInput: no owning Menu found in ancestors.")
		return
	if entry_menu_scene_path.is_empty():
		push_error("InsertPositionInput: entry_menu_scene_path not set.")
		return

	var container: Node = get_node_or_null(submenu_container_path)
	if container == null:
		push_error("InsertPositionInput: submenu_container_path not set or invalid.")
		return

	_entry_menu = load(entry_menu_scene_path).instantiate()

	if _entry_menu.has_method("set_options_data"):
		_entry_menu.set_options_data(_options_data, prompt_text)
	if _entry_menu.has_signal("position_selected"):
		_entry_menu.position_selected.connect(_on_position_selected)

	var submenu_key: String = "insert_position_entry_%d" % get_instance_id()
	_owning_menu.add_submenu(submenu_key, _entry_menu)
	_owning_menu.open_submenu(submenu_key, container)


func _on_position_selected(index: int) -> void:
	value_changed.emit(index)
	_close_entry_menu()


func _close_entry_menu() -> void:
	if _entry_menu:
		_entry_menu.request_close()
		if _owning_menu:
			var submenu_key: String = "insert_position_entry_%d" % get_instance_id()
			_owning_menu.remove_submenu(submenu_key)
		_entry_menu.queue_free()
		_entry_menu = null


func _find_owning_menu() -> Menu:
	var node: Node = get_parent()
	while node:
		if node is Menu:
			return node
		node = node.get_parent()
	return null
