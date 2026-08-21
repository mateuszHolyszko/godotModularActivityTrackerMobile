class_name PickExerciseButton
extends Button

signal value_changed(new_value)

@export var prompt_text: String = "Select exercise"
@export var entry_menu_scene_path: String = "res://elements/pickExercise/PickExerciseEntry.tscn"
@export var submenu_container_path: NodePath

var current_value = null:
	set(value):
		if value != current_value:
			current_value = value
			value_changed.emit(current_value)
		_update_text()

var _owning_menu: Menu
var _entry_menu: PickExerciseEntry


func _ready() -> void:
	pressed.connect(_on_pressed)
	_update_text()


func _update_text() -> void:
	text = "--" if current_value == null else str(current_value)


func _on_pressed() -> void:
	if _owning_menu == null:
		_owning_menu = _find_owning_menu()
	if _owning_menu == null:
		push_error("PickExerciseButton: no owning Menu found in ancestors.")
		return
	if entry_menu_scene_path.is_empty():
		push_error("PickExerciseButton: entry_menu_scene_path not set.")
		return

	var container: Node = get_node_or_null(submenu_container_path)
	if container == null:
		push_error("PickExerciseButton: submenu_container_path not set or invalid.")
		return

	var scene := load(entry_menu_scene_path)
	if scene == null:
		push_error("PickExerciseButton: failed to load entry menu scene.")
		return

	_entry_menu = scene.instantiate()
	_entry_menu.set_picker_data(DataManager.ExerciseManager, prompt_text)
	_entry_menu.exercise_selected.connect(_on_exercise_selected)

	var submenu_key := "pick_exercise_entry_%d" % get_instance_id()
	_owning_menu.add_submenu(submenu_key, _entry_menu)
	_owning_menu.open_submenu(submenu_key, container)


func _on_exercise_selected(exercise_name) -> void:
	current_value = exercise_name
	_close_entry_menu()


func _close_entry_menu() -> void:
	if not is_instance_valid(_entry_menu):
		_entry_menu = null
		return

	_entry_menu.request_close()
	if _owning_menu:
		var submenu_key := "pick_exercise_entry_%d" % get_instance_id()
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
