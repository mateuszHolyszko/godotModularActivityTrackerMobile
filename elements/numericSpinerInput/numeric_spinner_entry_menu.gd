class_name NumericSpinnerEntryMenu
extends Menu

signal value_confirmed(value: float)

@onready var initial_value_label: Label = %InitValueLabel
@onready var max_value_label: Label = %MaxValueLabel
@onready var min_value_label: Label = %MinValueLabel
@onready var prompt_label: Label = %Prompt
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var scroll_content: VBoxContainer = %ScrollContent
@onready var confirm_button: Button = %ConfirmButton
@onready var back_button: Button = %BackButton

## Visual tuning for the generated entry buttons.
@export var entry_button_min_height: float = 150.0
@export var entry_button_font_size: int = 135

var _initial_value: float
var _min: float
var _max: float
var _step: float
var _prompt_text: String

var _selected_value: int = 0
var _value_buttons: Dictionary = {}  # int value -> Button
var _button_group: ButtonGroup


func set_initial_value(value: float, min_value: float, max_value: float, step: float, prompt: String) -> void:
	_initial_value = value
	_min = min_value
	_max = max_value
	_step = step
	_prompt_text = prompt


func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_scroll_to_selected()


func _on_open() -> void:
	# Spinner is integer-only: round/clamp everything up front.
	var min_i: int = int(round(_min))
	var max_i: int = int(round(_max))
	var step_i: int = max(int(round(_step)), 1)
	var init_i: int = clampi(int(round(_initial_value)), min_i, max_i)

	initial_value_label.text = "Init val\n%d" % init_i
	max_value_label.text = "max\n%d" % max_i
	min_value_label.text = "min\n%d" % min_i
	prompt_label.text = _prompt_text

	_selected_value = init_i
	_populate_spinner(min_i, max_i, step_i)
	
	await get_tree().process_frame
	_scroll_to_selected()


func _populate_spinner(min_i: int, max_i: int, step_i: int) -> void:
	for child in scroll_content.get_children():
		child.queue_free()
	_value_buttons.clear()
	_button_group = ButtonGroup.new()

	var value := min_i
	while value <= max_i:
		_add_value_button(value)
		value += step_i

	# Guarantee max is always reachable even when it doesn't land exactly
	# on a step boundary (e.g. min=0, max=10, step=3).
	if not _value_buttons.has(max_i):
		_add_value_button(max_i)


func _add_value_button(value: int) -> void:
	var btn := Button.new()
	btn.text = str(value)
	btn.toggle_mode = true
	btn.button_group = _button_group
	btn.custom_minimum_size = Vector2(0, entry_button_min_height)
	btn.add_theme_font_size_override("font_size", entry_button_font_size)
	btn.pressed.connect(_on_value_button_pressed.bind(value))
	scroll_content.add_child(btn)
	_value_buttons[value] = btn

	if value == _selected_value:
		btn.set_pressed_no_signal(true)


func _on_value_button_pressed(value: int) -> void:
	_selected_value = value


func _scroll_to_selected() -> void:
	if not _value_buttons.has(_selected_value):
		return
	var btn: Button = _value_buttons[_selected_value]
	# Wait a frame so the ScrollContainer and its children have been laid
	# out (sizes/positions are correct) before we compute a scroll offset.
	await get_tree().process_frame

	var viewport_height: float = scroll_container.size.y
	var btn_center_y: float = btn.position.y + (btn.size.y / 2.0)
	var target_scroll: float = btn_center_y - (viewport_height / 2.0)

	var max_scroll: float = scroll_content.size.y - viewport_height
	target_scroll = clampf(target_scroll, 0.0, max(max_scroll, 0.0))

	scroll_container.scroll_vertical = int(round(target_scroll))


func _on_confirm_pressed() -> void:
	value_confirmed.emit(float(_selected_value))


func _on_back_pressed() -> void:
	request_close()
