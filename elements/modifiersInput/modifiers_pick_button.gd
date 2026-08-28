class_name ModifierPickButton
extends Button

signal value_changed(new_value)
signal on_set(new_value)

@export var submenu_container_path: NodePath

var current_value = null:
	set(v):
		if v != current_value:
			current_value = v
			value_changed.emit(current_value)

var entry_menu_scene_path: String = "res://elements/modifiersInput/ModifiersPickMenu.tscn"

# Store current modifiers
var current_modifiers: Array[String] = []

var _owning_menu: Menu
var _entry_menu: Menu

func _ready() -> void:
	pressed.connect(_on_pressed)

func set_modifiers(modifiers: Array[String]) -> void:
	"""
	Set the current modifiers for the button.
	"""
	current_modifiers = modifiers.duplicate()
	on_set.emit(current_modifiers)

func get_modifiers() -> Array[String]:
	"""
	Get the current modifiers.
	"""
	return current_modifiers.duplicate()

func _on_pressed() -> void:
	if _owning_menu == null:
		_owning_menu = _find_owning_menu()
	if _owning_menu == null:
		push_error("ModifierPickButton: no owning Menu found in ancestors.")
		return
	if entry_menu_scene_path.is_empty():
		push_error("ModifierPickButton: entry_menu_scene_path not set.")
		return

	var container: Node = get_node_or_null(submenu_container_path)
	if container == null:
		push_error("ModifierPickButton: submenu_container_path not set or invalid.")
		return

	_entry_menu = load(entry_menu_scene_path).instantiate()

	# Pass the current modifiers to the menu
	if _entry_menu.has_method("set_current_modifiers"):
		_entry_menu.set_current_modifiers(current_modifiers)
	
	# Connect the confirm signal
	if _entry_menu.has_signal("modifiers_confirmed"):
		_entry_menu.modifiers_confirmed.connect(_on_modifiers_confirmed)
	
	# Connect the cancelled signal
	if _entry_menu.has_signal("modifiers_cancelled"):
		_entry_menu.modifiers_cancelled.connect(_on_modifiers_cancelled)

	var submenu_key: String = "modifier_entry_%d" % get_instance_id()
	_owning_menu.add_submenu(submenu_key, _entry_menu)
	_owning_menu.open_submenu(submenu_key, container)

func _on_modifiers_confirmed(modifiers: Array[String]) -> void:
	"""
	Handle when modifiers are confirmed in the menu.
	"""
	current_modifiers = modifiers.duplicate()
	value_changed.emit(current_modifiers)
	_close_entry_menu()

func _on_modifiers_cancelled() -> void:
	"""
	Handle when modifiers are cancelled in the menu.
	"""
	_close_entry_menu()

func _close_entry_menu() -> void:
	if _entry_menu:
		_entry_menu.request_close()
		if _owning_menu:
			var submenu_key: String = "modifier_entry_%d" % get_instance_id()
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
