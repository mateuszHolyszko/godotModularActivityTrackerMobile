class_name OptionInputButton
extends Button

signal value_changed(new_value)

@export var prompt_text: String = ""
@export var options: Array[String] = []   # simple case: label == value, editor-settable
@export var entry_menu_scene_path: String = ""
@export var submenu_container_path: NodePath

var current_value = null:
	set(v):
		if v != current_value:
			current_value = v
			value_changed.emit(current_value)
		_update_text()

var _options_data: Array = []   # use set_options_data() to override with {label,value} dicts
var _owning_menu: Menu
var _entry_menu: Menu


func _ready() -> void:
	pressed.connect(_on_pressed)
	if _options_data.is_empty() and not options.is_empty():
		_options_data = options.duplicate()
	_update_text()
	# current_value stays null until the user picks something


func set_options_data(data: Array) -> void:
	_options_data = data
	_update_text()


func _get_value(opt):
	return opt.get("value") if opt is Dictionary else opt


func _get_label(opt) -> String:
	return str(opt.get("label", opt.get("value"))) if opt is Dictionary else str(opt)


func _update_text() -> void:
	var label_str: String = ""
	for opt in _options_data:
		if current_value != null and _get_value(opt) == current_value:
			label_str = _get_label(opt)
			break
	if label_str.is_empty():
		label_str = "--" if current_value == null else str(current_value)

	if prompt_text.is_empty():
		text = label_str
	else:
		text = "%s\n%s" % [prompt_text, label_str]


func _on_pressed() -> void:
	if _owning_menu == null:
		_owning_menu = _find_owning_menu()
	if _owning_menu == null:
		push_error("OptionInputButton: no owning Menu found in ancestors.")
		return
	if entry_menu_scene_path.is_empty():
		push_error("OptionInputButton: entry_menu_scene_path not set.")
		return

	var container: Node = get_node_or_null(submenu_container_path)
	if container == null:
		push_error("OptionInputButton: submenu_container_path not set or invalid.")
		return

	_entry_menu = load(entry_menu_scene_path).instantiate()

	if _entry_menu.has_method("set_options_data"):
		_entry_menu.set_options_data(_options_data, current_value, prompt_text)
	if _entry_menu.has_signal("option_selected"):
		_entry_menu.option_selected.connect(_on_option_selected)

	var submenu_key: String = "option_entry_%d" % get_instance_id()
	_owning_menu.add_submenu(submenu_key, _entry_menu)
	_owning_menu.open_submenu(submenu_key, container)


func _on_option_selected(value) -> void:
	current_value = value
	_close_entry_menu()


func _close_entry_menu() -> void:
	if _entry_menu:
		_entry_menu.request_close()
		if _owning_menu:
			var submenu_key: String = "option_entry_%d" % get_instance_id()
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
