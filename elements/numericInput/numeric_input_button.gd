class_name NumericInputButton
extends Button

signal value_changed(new_value: float)

@export var prompt_text: String = ""
@export var suffix_text: String = ""
@export var is_int: bool = false
@export var increment_value: float = 1.0
@export var min_value: float = 0.0
@export var max_value: float = 100.0
@export var entry_menu_scene_path: String = ""
@export var submenu_container_path: NodePath  # where the entry submenu should appear

var current_value: float = 0.0:
	set(v):
		var new_val: float = v
		if is_int:
			new_val = round(new_val)
		var clamped: float = clamp(new_val, min_value, max_value)
		if clamped != current_value:
			current_value = clamped
			value_changed.emit(current_value)
		_update_text()

var _owning_menu: Menu
var _entry_menu: Menu


func _ready() -> void:
	pressed.connect(_on_pressed)
	_update_text()


func _update_text() -> void:
	var value_str: String
	
	if is_int:
		value_str = str(int(current_value))
	else:
		# Format to 2 decimal places
		value_str = "%.2f" % current_value
	
	var body: String = value_str
	if not suffix_text.is_empty():
		body += suffix_text
	
	if prompt_text.is_empty():
		text = body
	else:
		text = "%s: %s" % [prompt_text, body]


func _on_pressed() -> void:
	if _owning_menu == null:
		_owning_menu = _find_owning_menu()
	if _owning_menu == null:
		push_error("NumericInputButton: no owning Menu found in ancestors.")
		return
	if entry_menu_scene_path.is_empty():
		push_error("NumericInputButton: entry_menu_scene_path not set.")
		return

	var container: Node = get_node_or_null(submenu_container_path)
	if container == null:
		push_error("NumericInputButton: submenu_container_path not set or invalid.")
		return

	_entry_menu = load(entry_menu_scene_path).instantiate()

	# Propagate is_int since the entry menu's export can't be set from the editor here
	if "is_int" in _entry_menu:
		_entry_menu.is_int = is_int

	if _entry_menu.has_method("set_initial_value"):
		_entry_menu.set_initial_value(current_value, min_value, max_value, increment_value, prompt_text)
	if _entry_menu.has_signal("value_confirmed"):
		_entry_menu.value_confirmed.connect(_on_value_confirmed)

	var submenu_key: String = "numeric_entry_%d" % get_instance_id()
	_owning_menu.add_submenu(submenu_key, _entry_menu)
	_owning_menu.open_submenu(submenu_key, container)


func _on_value_confirmed(new_value: float) -> void:
	current_value = new_value
	_close_entry_menu()


func _close_entry_menu() -> void:
	if _entry_menu:
		_entry_menu.request_close()
		if _owning_menu:
			var submenu_key: String = "numeric_entry_%d" % get_instance_id()
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
