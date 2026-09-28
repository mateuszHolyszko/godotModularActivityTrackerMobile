class_name DateInputMenu
extends Menu

signal value_confirmed(duration: Dictionary)

@onready var date_picker: DateScrollPicker = %DatePicker
@onready var today_date_label: Label = %TodayDateLabel  # "Today:\ndd-mm-yyyy"
@onready var query_end_date_label: Label = %QueryEndDateLabel  # "Query result date:\ndd-mm-yyyy"
@onready var confirm_button: Button = %ConfirmButton
@onready var back_button: Button = %BackButton
@onready var prompt_label: Label = %PromptLabel

## Forwarded to the picker.
@export var item_height: float = 150.0
@export var font_size: int = 135

## Upper bound for the "years" spinner (0..max_years_offset). Each month in
## the duration is treated as 31 days when computing the query end date.
@export var max_years_offset: int = 10

## If true (default), the picked duration is subtracted from today (query
## date is in the past). If false, it's added instead (future date).
@export var subtract_from_today: bool = true

var _initial_duration: Dictionary = {"day": 0, "month": 0, "year": 0}
var _prompt_text: String


func set_initial_value(initial_duration: Dictionary, prompt: String) -> void:
	_initial_duration = initial_duration
	_prompt_text = prompt


func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)

	prompt_label.text = "Provide numbers from today" if subtract_from_today \
		else "Provide numbers since today"

	# Configure the picker before its deferred _build() runs.
	date_picker.item_height = item_height
	date_picker.font_size = font_size
	date_picker.max_years_offset = max_years_offset
	date_picker.subtract_from_today = subtract_from_today
	date_picker.duration_changed.connect(_on_duration_changed)


func _on_open() -> void:
	date_picker.set_duration(_initial_duration)
	_update_labels()


func _on_duration_changed(_duration: Dictionary) -> void:
	_update_labels()


func _update_labels() -> void:
	today_date_label.text = "Today:\n%s" % _format_date(Time.get_date_dict_from_system())
	query_end_date_label.text = "Query result date:\n%s" % _format_date(date_picker.get_current_date())


func _format_date(date: Dictionary) -> String:
	return "%02d-%02d-%04d" % [date.day, date.month, date.year]


func _on_confirm_pressed() -> void:
	value_confirmed.emit(date_picker.get_duration())


func _on_back_pressed() -> void:
	request_close()
