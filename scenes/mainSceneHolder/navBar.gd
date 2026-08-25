extends Node

@onready var initButton: Button = %ButtonInit
@onready var sessionButton: Button = %ButtonSession
@onready var programButton: Button = %ButtonProgram
@onready var dataButton: Button = %ButtonData


func _ready() -> void:
	initButton.pressed.connect(_on_init_pressed)
	sessionButton.pressed.connect(_on_session_pressed)
	programButton.pressed.connect(_on_program_pressed)
	dataButton.pressed.connect(_on_data_pressed)

	MenuManager.all_preloads_finished.connect(_on_all_preloads_finished)
	_set_buttons_disabled(true)


func _on_init_pressed() -> void:
	MenuManager.switch_to("init")
	_set_active_button(initButton)


func _on_session_pressed() -> void:
	MenuManager.switch_to("session")
	_set_active_button(sessionButton)


func _on_program_pressed() -> void:
	MenuManager.switch_to("program")
	_set_active_button(programButton)


func _on_data_pressed() -> void:
	MenuManager.switch_to("data")
	_set_active_button(dataButton)


func _on_all_preloads_finished() -> void:
	_set_buttons_disabled(false)


func _set_buttons_disabled(disabled: bool) -> void:
	for button in [initButton, sessionButton, programButton, dataButton]:
		button.disabled = disabled


func _set_active_button(active_button: Button) -> void:
	# Get all button nodes
	var buttons = [initButton, sessionButton, programButton, dataButton]

	# Disable toggle mode for all buttons first
	for button in buttons:
		button.toggle_mode = false
		button.mouse_filter = Control.MOUSE_FILTER_STOP

	# Set the active button's toggle mode and press it
	active_button.mouse_filter = Control.MOUSE_FILTER_IGNORE # So that we cant re-enter same menu we are currently in
	active_button.toggle_mode = true
	active_button.button_pressed = true
