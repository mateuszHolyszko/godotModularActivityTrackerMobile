class_name TextInputButton
extends Button

signal value_changed(new_value: String)

@export var prompt_text: String = ""
@export var placeholder_text: String = "--"
@export var max_length: int = -1
@export var entry_menu_scene_path: String = ""
@export var submenu_container_path: NodePath

var current_value: String = "":
	set(v):
		if v != current_value:
			current_value = v
			value_changed.emit(current_value)
		_update_text()

var _owning_menu: Menu
var _entry_menu: Menu


func _ready() -> void:
	pressed.connect(_on_pressed)
	_update_text()


func _update_text() -> void:
	var display_str: String = current_value if not current_value.is_empty() else placeholder_text
	text = display_str if prompt_text.is_empty() else "%s\n%s" % [prompt_text, display_str]


func _on_pressed() -> void:
	if _owning_menu == null:
		_owning_menu = _find_owning_menu()
	if _owning_menu == null:
		push_error("TextInputButton: no owning Menu found in ancestors.")
		return
	if entry_menu_scene_path.is_empty():
		push_error("TextInputButton: entry_menu_scene_path not set.")
		return

	var container: Node = get_node_or_null(submenu_container_path)
	if container == null:
		push_error("TextInputButton: submenu_container_path not set or invalid.")
		return

	_entry_menu = load(entry_menu_scene_path).instantiate()

	if _entry_menu.has_method("set_text_data"):
		_entry_menu.set_text_data(current_value, prompt_text, max_length)
	if _entry_menu.has_signal("text_confirmed"):
		_entry_menu.text_confirmed.connect(_on_text_confirmed)

	var submenu_key: String = "text_entry_%d" % get_instance_id()
	_owning_menu.add_submenu(submenu_key, _entry_menu)
	_owning_menu.open_submenu(submenu_key, container)


func _on_text_confirmed(value: String) -> void:
	current_value = value
	_close_entry_menu()


func _close_entry_menu() -> void:
	if _entry_menu:
		_entry_menu.request_close()
		if _owning_menu:
			var submenu_key: String = "text_entry_%d" % get_instance_id()
			_owning_menu.remove_submenu(submenu_key)
		_entry_menu.queue_free()
		_entry_menu = null


func _find_owning_menu() -> Menu:
	var n: Node = get_parent()
	while n:
		if n is Menu:
			return n
		n = n.get_parent()
	return null
