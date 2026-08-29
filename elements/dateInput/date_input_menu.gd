class_name DateInputMenu
extends Menu

signal value_confirmed(duration: Dictionary)

@onready var scroll_content_year: VBoxContainer = %ScrollContentYear
@onready var scroll_content_month: VBoxContainer = %ScrollContentMonth
@onready var scroll_content_day: VBoxContainer = %ScrollContentDay
@onready var today_date_label: Label = %TodayDateLabel  # format "Today:\ndd-mm-yyyy"
@onready var query_end_date_label: Label = %QueryEndDateLabel  # format "Query date:\ndd-mm-yyyy", take time inputed, and add it to today, convert back to date
@onready var confirm_button: Button = %ConfirmButton
@onready var back_button: Button = %BackButton

## Visual tuning for the generated entry buttons.
@export var entry_button_min_height: float = 150.0
@export var entry_button_font_size: int = 135

## Upper bound for the "years" spinner (0..max_years_offset). Each month in
## the duration is treated as 31 days when computing the query end date.
@export var max_years_offset: int = 10

## If true (default), the picked duration is subtracted from today (query
## date is in the past). If false, it's added instead (future date).
@export var subtract_from_today: bool = true

const _DAY_MAX: int = 31
const _MONTH_MAX: int = 12

var _initial_duration: Dictionary = {"day": 0, "month": 0, "year": 0}
var _prompt_text: String

# Per-column state, keyed by "day" / "month" / "year".
var _selected: Dictionary = {"day": 0, "month": 0, "year": 0}
var _value_buttons: Dictionary = {"day": {}, "month": {}, "year": {}}
var _button_groups: Dictionary = {"day": null, "month": null, "year": null}


func set_initial_value(initial_duration: Dictionary, prompt: String) -> void:
	_initial_duration = initial_duration
	_prompt_text = prompt


func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)


func _on_open() -> void:
	_selected["day"] = clampi(int(_initial_duration.get("day", 0)), 0, _DAY_MAX)
	_selected["month"] = clampi(int(_initial_duration.get("month", 0)), 0, _MONTH_MAX)
	_selected["year"] = clampi(int(_initial_duration.get("year", 0)), 0, max_years_offset)

	_populate_spinner("day", scroll_content_day, 0, _DAY_MAX)
	_populate_spinner("month", scroll_content_month, 0, _MONTH_MAX)
	_populate_spinner("year", scroll_content_year, 0, max_years_offset)

	_update_labels()

	await get_tree().process_frame
	_scroll_to_selected("day", scroll_content_day)
	_scroll_to_selected("month", scroll_content_month)
	_scroll_to_selected("year", scroll_content_year)


func _populate_spinner(column: String, content: VBoxContainer, min_i: int, max_i: int) -> void:
	for child in content.get_children():
		child.queue_free()
	_value_buttons[column].clear()
	_button_groups[column] = ButtonGroup.new()

	for value in range(min_i, max_i + 1):
		_add_value_button(column, content, value)


func _add_value_button(column: String, content: VBoxContainer, value: int) -> void:
	var btn := Button.new()
	btn.text = str(value)
	btn.toggle_mode = true
	btn.button_group = _button_groups[column]
	btn.custom_minimum_size = Vector2(0, entry_button_min_height)
	btn.add_theme_font_size_override("font_size", entry_button_font_size)
	btn.pressed.connect(_on_value_button_pressed.bind(column, value))
	content.add_child(btn)
	_value_buttons[column][value] = btn

	if value == _selected[column]:
		btn.set_pressed_no_signal(true)


func _on_value_button_pressed(column: String, value: int) -> void:
	_selected[column] = value
	_update_labels()


func _scroll_to_selected(column: String, content: VBoxContainer) -> void:
	var buttons: Dictionary = _value_buttons[column]
	if not buttons.has(_selected[column]):
		return
	var scroll_container: ScrollContainer = content.get_parent() as ScrollContainer
	if scroll_container == null:
		return

	var btn: Button = buttons[_selected[column]]
	# Wait a frame so the ScrollContainer and its children have been laid
	# out (sizes/positions are correct) before we compute a scroll offset.
	await get_tree().process_frame

	var viewport_height: float = scroll_container.size.y
	var btn_center_y: float = btn.position.y + (btn.size.y / 2.0)
	var target_scroll: float = btn_center_y - (viewport_height / 2.0)

	var max_scroll: float = content.size.y - viewport_height
	target_scroll = clampf(target_scroll, 0.0, max(max_scroll, 0.0))

	scroll_container.scroll_vertical = int(round(target_scroll))


func _update_labels() -> void:
	var today: Dictionary = Time.get_date_dict_from_system()
	today_date_label.text = "Today:\n%s" % _format_date(today)

	# Take the time inputted (day/month/year spinners, months assumed 31 days)
	# and apply it to today, then convert back to a date.
	var offset_days: int = _selected.year * 365 + _selected.month * 31 + _selected.day
	if subtract_from_today:
		offset_days = -offset_days
	var today_unix: int = Time.get_unix_time_from_datetime_dict(today)
	var target_unix: int = today_unix + offset_days * 86400
	var target_date: Dictionary = Time.get_date_dict_from_unix_time(target_unix)

	query_end_date_label.text = "Query date:\n%s" % _format_date(target_date)


func _format_date(date: Dictionary) -> String:
	return "%02d-%02d-%04d" % [date.day, date.month, date.year]


func _on_confirm_pressed() -> void:
	value_confirmed.emit({"day": _selected.day, "month": _selected.month, "year": _selected.year})


func _on_back_pressed() -> void:
	request_close()
