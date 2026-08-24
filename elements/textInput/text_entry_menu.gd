class_name TextEntryMenu
extends Menu

signal text_confirmed(value: String)

@onready var prompt_label: Label = %Prompt
@onready var buffer_label: Label = %TextBufferLabel
@onready var cancel_button: Button = %CancelButton
@onready var enter_button: Button = %EnterButton
@onready var clear_button: Button = %ClearButton
@onready var backspace_button: Button = %BackSpaceButton
@onready var space_button: Button = %SpaceButton
@onready var new_line_button: Button = %NewLineButton

@onready var key_q: Button = %Key_Q
@onready var key_w: Button = %Key_W
@onready var key_e: Button = %Key_E
@onready var key_r: Button = %Key_R
@onready var key_t: Button = %Key_T
@onready var key_y: Button = %Key_Y
@onready var key_u: Button = %Key_U
@onready var key_i: Button = %Key_I
@onready var key_o: Button = %Key_O
@onready var key_p: Button = %Key_P
@onready var key_a: Button = %Key_A
@onready var key_s: Button = %Key_S
@onready var key_d: Button = %Key_D
@onready var key_f: Button = %Key_F
@onready var key_g: Button = %Key_G
@onready var key_h: Button = %Key_H
@onready var key_j: Button = %Key_J
@onready var key_k: Button = %Key_K
@onready var key_l: Button = %Key_L
@onready var key_z: Button = %Key_Z
@onready var key_x: Button = %Key_X
@onready var key_c: Button = %Key_C
@onready var key_v: Button = %Key_V
@onready var key_b: Button = %Key_B
@onready var key_n: Button = %Key_N
@onready var key_m: Button = %Key_M

@onready var key_1: Button = %Key_1
@onready var key_2: Button = %Key_2
@onready var key_3: Button = %Key_3
@onready var key_4: Button = %Key_4
@onready var key_5: Button = %Key_5
@onready var key_6: Button = %Key_6
@onready var key_7: Button = %Key_7
@onready var key_8: Button = %Key_8
@onready var key_9: Button = %Key_9
@onready var key_0: Button = %Key_0

var _text_buffer: String = ""
var _prompt_text: String = ""
var _max_length: int = -1   # -1 = unlimited

# Cursor blinking variables
var _cursor_visible: bool = true
var _cursor_timer: Timer


func set_text_data(current_value: String = "", prompt: String = "", max_length: int = -1) -> void:
	_text_buffer = current_value
	_prompt_text = prompt
	_max_length = max_length


func _ready() -> void:
	cancel_button.pressed.connect(_on_cancel_pressed)
	enter_button.pressed.connect(_on_enter_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	backspace_button.pressed.connect(_on_backspace_pressed)
	space_button.pressed.connect(_on_key_pressed.bind(" "))
	new_line_button.pressed.connect(_on_new_line_pressed)
	_connect_key_buttons()
	
	# Setup cursor blinking timer
	_cursor_timer = Timer.new()
	_cursor_timer.wait_time = 0.5
	_cursor_timer.autostart = true
	_cursor_timer.timeout.connect(_toggle_cursor)
	add_child(_cursor_timer)


func _connect_key_buttons() -> void:
	var key_map := {
		key_1: "1", key_2: "2", key_3: "3", key_4: "4", key_5: "5", key_6: "6", key_7: "7", key_8: "8", key_9: "9", key_0: "0",
		key_q: "q", key_w: "w", key_e: "e", key_r: "r", key_t: "t",
		key_y: "y", key_u: "u", key_i: "i", key_o: "o", key_p: "p",
		key_a: "a", key_s: "s", key_d: "d", key_f: "f", key_g: "g",
		key_h: "h", key_j: "j", key_k: "k", key_l: "l",
		key_z: "z", key_x: "x", key_c: "c", key_v: "v",
		key_b: "b", key_n: "n", key_m: "m",
	}
	for btn: Button in key_map:
		btn.pressed.connect(_on_key_pressed.bind(key_map[btn]))


func _on_open() -> void:
	prompt_label.text = _prompt_text
	_update_buffer_display()
	# Reset cursor visibility when menu opens
	_cursor_visible = true
	_cursor_timer.start()


func _on_close() -> void:
	# Stop timer when menu closes
	_cursor_timer.stop()


func _on_key_pressed(letter: String) -> void:
	if _max_length >= 0 and _text_buffer.length() >= _max_length:
		return
	_text_buffer += letter
	_update_buffer_display()
	# Reset cursor visibility to ensure it's visible after typing
	_cursor_visible = true


func _on_backspace_pressed() -> void:
	if _text_buffer.length() > 0:
		_text_buffer = _text_buffer.substr(0, _text_buffer.length() - 1)
	_update_buffer_display()
	_cursor_visible = true


func _on_clear_pressed() -> void:
	_text_buffer = ""
	_update_buffer_display()
	_cursor_visible = true


func _on_enter_pressed() -> void:
	text_confirmed.emit(_text_buffer)


func _on_cancel_pressed() -> void:
	request_close()


func _on_new_line_pressed() -> void:
	if _max_length >= 0 and _text_buffer.length() >= _max_length:
		return
	_text_buffer += "\n"
	_update_buffer_display()
	_cursor_visible = true


func _toggle_cursor() -> void:
	_cursor_visible = !_cursor_visible
	_update_buffer_display()


func _update_buffer_display() -> void:
	# Always show a character at the end to maintain text position
	# Alternate between underscore and space for blinking effect
	var cursor_char = "_" if _cursor_visible else " "
	buffer_label.text = _text_buffer + cursor_char
