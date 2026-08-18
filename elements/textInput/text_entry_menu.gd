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

var _text_buffer: String = ""
var _prompt_text: String = ""
var _max_length: int = -1   # -1 = unlimited


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
	_connect_key_buttons()


func _connect_key_buttons() -> void:
	var key_map := {
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


func _on_key_pressed(letter: String) -> void:
	if _max_length >= 0 and _text_buffer.length() >= _max_length:
		return
	_text_buffer += letter
	_update_buffer_display()


func _on_backspace_pressed() -> void:
	if _text_buffer.length() > 0:
		_text_buffer = _text_buffer.substr(0, _text_buffer.length() - 1)
	_update_buffer_display()


func _on_clear_pressed() -> void:
	_text_buffer = ""
	_update_buffer_display()


func _on_enter_pressed() -> void:
	text_confirmed.emit(_text_buffer)


func _on_cancel_pressed() -> void:
	request_close()


func _update_buffer_display() -> void:
	buffer_label.text = _text_buffer
