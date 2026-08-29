class_name DateInputButton
extends Button

signal date_changed(new_date: Dictionary)
signal date_confirmed(new_date: Dictionary)

@export var prompt_text: String = ""
@export var entry_menu_scene_path: String = ""
@export var submenu_container_path: NodePath  # where the entry submenu should appear

@export var include_prompt_text_in_button: bool = true

## Upper bound for the "years" spinner in the entry menu (0..max_years_offset).
@export var max_years_offset: int = 10

## If true (default), the picked duration is subtracted from today, giving a
## date in the past - e.g. "query the last N weeks". If false, the duration
## is added to today instead, giving a date in the future.
@export var subtract_from_today: bool = true

## Optional starting duration, as (day, month, year). Defaults to (0,0,0),
## i.e. today. Only applied once, on _ready().
@export var initial_date: Vector3i = Vector3i.ZERO

# The button doesn't store an absolute date directly - it stores a duration
# (days/months/years) that gets applied to "today" to produce the date that's
# actually shown on the button and reported to listeners. This matches how
# the entry menu computes its "Query end date" label.
var current_duration: Dictionary = {"day": 0, "month": 0, "year": 0}:
	set(v):
		var new_val: Dictionary = {
			"day": clampi(int(v.get("day", 0)), 0, 31),
			"month": clampi(int(v.get("month", 0)), 0, 12),
			"year": clampi(int(v.get("year", 0)), 0, max_years_offset),
		}
		if new_val != current_duration:
			current_duration = new_val
			date_changed.emit(get_current_date())
		_update_text()

var _owning_menu: Menu
var _entry_menu: Menu


func _ready() -> void:
	pressed.connect(_on_pressed)
	current_duration = {"day": initial_date.x, "month": initial_date.y, "year": initial_date.z}
	_update_text()


## Returns the actual date represented by this button: today with
## current_duration subtracted (or added, if subtract_from_today is false),
## with each month in the duration treated as 31 days.
func get_current_date() -> Dictionary:
	var today: Dictionary = Time.get_date_dict_from_system()
	var offset_days: int = current_duration.year * 365 + current_duration.month * 31 + current_duration.day
	if subtract_from_today:
		offset_days = -offset_days
	var today_unix: int = Time.get_unix_time_from_datetime_dict(today)
	var target_unix: int = today_unix + offset_days * 86400
	return Time.get_date_dict_from_unix_time(target_unix)


func _update_text() -> void:
	var date: Dictionary = get_current_date()
	var body: String = "%02d-%02d-%04d" % [date.day, date.month, date.year]

	if prompt_text.is_empty() or include_prompt_text_in_button == false:
		text = body
	else:
		text = "%s: %s" % [prompt_text, body]


func _on_pressed() -> void:
	if _owning_menu == null:
		_owning_menu = _find_owning_menu()
	if _owning_menu == null:
		push_error("DataInputButton: no owning Menu found in ancestors.")
		return
	if entry_menu_scene_path.is_empty():
		push_error("DataInputButton: entry_menu_scene_path not set.")
		return

	var container: Node = get_node_or_null(submenu_container_path)
	if container == null:
		push_error("DataInputButton: submenu_container_path not set or invalid.")
		return

	_entry_menu = load(entry_menu_scene_path).instantiate()

	# Propagate exports since the entry menu's can't be set from the editor here
	if "max_years_offset" in _entry_menu:
		_entry_menu.max_years_offset = max_years_offset
	if "subtract_from_today" in _entry_menu:
		_entry_menu.subtract_from_today = subtract_from_today

	if _entry_menu.has_method("set_initial_value"):
		_entry_menu.set_initial_value(current_duration, prompt_text)
	if _entry_menu.has_signal("value_confirmed"):
		_entry_menu.value_confirmed.connect(_on_value_confirmed)

	var submenu_key: String = "data_entry_%d" % get_instance_id()
	_owning_menu.add_submenu(submenu_key, _entry_menu)
	_owning_menu.open_submenu(submenu_key, container)


func _on_value_confirmed(new_duration: Dictionary) -> void:
	current_duration = new_duration
	date_confirmed.emit(get_current_date())
	_close_entry_menu()


func _close_entry_menu() -> void:
	if _entry_menu:
		_entry_menu.request_close()
		if _owning_menu:
			var submenu_key: String = "data_entry_%d" % get_instance_id()
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
