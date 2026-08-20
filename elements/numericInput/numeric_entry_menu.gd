class_name NumericEntryMenu
extends Menu

signal value_confirmed(value: float)

@export var is_int: bool = false

@onready var initial_value_label: Label = %InitValueLabel
@onready var max_value_label: Label = %MaxValueLabel
@onready var min_value_label: Label = %MinValueLabel
@onready var prompt_label: Label = %Prompt


@onready var current_value_buffer_label: Label = %CurrentValBufferLabel
@onready var clear_button: Button = %ClearButton
@onready var back_space_button: Button = %BackSpaceButton
@onready var num1_button: Button = %Num1
@onready var num2_button: Button = %Num2
@onready var num3_button: Button = %Num3
@onready var num4_button: Button = %Num4
@onready var num5_button: Button = %Num5
@onready var num6_button: Button = %Num6
@onready var num7_button: Button = %Num7
@onready var num8_button: Button = %Num8
@onready var num9_button: Button = %Num9
@onready var num0_button: Button = %Num0
@onready var period_button: Button = %Period
@onready var confirm_button: Button = %ConfirmButton
@onready var back_button: Button = %BackButton

var _initial_value: float
var _min: float
var _max: float
var _step: float
var _prompt_text: String

var _buffer: String = ""


func set_initial_value(value: float, min_value: float, max_value: float, step: float, prompt: String) -> void:
	_initial_value = value
	_min = min_value
	_max = max_value
	_step = step
	_prompt_text = prompt


func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	back_space_button.pressed.connect(_on_backspace_pressed)
	period_button.pressed.connect(_on_period_pressed)

	var digit_buttons: Array[Button] = [
		num0_button, num1_button, num2_button, num3_button, num4_button,
		num5_button, num6_button, num7_button, num8_button, num9_button,
	]
	for i in digit_buttons.size():
		digit_buttons[i].pressed.connect(_on_digit_pressed.bind(str(i)))

	period_button.disabled = is_int


func _on_open() -> void:
	# Format values to 2 decimal places for display
	var value_formatter := "%.2f" if not is_int else "%d"
	
	initial_value_label.text = "Init val\n" + (value_formatter % _initial_value)
	max_value_label.text = "max\n" + (value_formatter % _max)
	min_value_label.text = "min\n" + (value_formatter % _min)
	prompt_label.text = _prompt_text
	_buffer = ""
	_update_buffer_label()



func _on_digit_pressed(digit: String) -> void:
	# Prevent multiple leading zeros, but otherwise just append
	if _buffer == "0":
		_buffer = digit
	else:
		_buffer += digit
	_update_buffer_label()


func _on_period_pressed() -> void:
	if is_int:
		return
	if _buffer.is_empty():
		_buffer = "0."
	elif not _buffer.contains("."):
		_buffer += "."
	_update_buffer_label()


func _on_clear_pressed() -> void:
	_buffer = ""
	_update_buffer_label()


func _on_backspace_pressed() -> void:
	if _buffer.length() > 0:
		_buffer = _buffer.substr(0, _buffer.length() - 1)
	_update_buffer_label()


func _update_buffer_label() -> void:
	current_value_buffer_label.text = _buffer if not _buffer.is_empty() else "0"


func _on_confirm_pressed() -> void:
	var entered: float = float(_buffer) if not _buffer.is_empty() else _initial_value
	if is_int:
		entered = round(entered)

	if entered < _min or entered > _max:
		var value_formatter := "%.2f" if not is_int else "%d"
		NotificationManager.error(
			"Value must be between %s and %s" % [value_formatter % _min, value_formatter % _max]
		)
		_buffer = ""
		_update_buffer_label()
		return

	value_confirmed.emit(entered)


func _on_back_pressed() -> void:
	request_close()
