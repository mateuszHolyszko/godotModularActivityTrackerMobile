extends Node

@onready var initButton: Button = %ButtonInit
@onready var sessionButton: Button = %ButtonSession
@onready var programButton: Button = %ButtonProgram
@onready var exercisesButton: Button = %ButtonExercise
@onready var statsButton: Button = %ButtonStats
@onready var dataButton: Button = %ButtonData
@onready var settingsButton: Button = %ButtonSettings


func _ready() -> void:
	initButton.pressed.connect(_on_init_pressed)
	sessionButton.pressed.connect(_on_session_pressed)
	programButton.pressed.connect(_on_program_pressed)
	exercisesButton.pressed.connect(_on_exercises_pressed)
	statsButton.pressed.connect(_on_stats_pressed)
	dataButton.pressed.connect(_on_data_pressed)
	settingsButton.pressed.connect(_on_settings_pressed)

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


func _on_exercises_pressed() -> void:
	MenuManager.switch_to("exercises")
	_set_active_button(exercisesButton)
	
func _on_stats_pressed() -> void:
	MenuManager.switch_to("stats")
	_set_active_button(statsButton)
	
func _on_data_pressed() -> void:
	MenuManager.switch_to("data")
	_set_active_button(dataButton)

func _on_settings_pressed() -> void:
	MenuManager.switch_to("settings")
	_set_active_button(settingsButton)

func _on_all_preloads_finished() -> void:
	_set_buttons_disabled(false)


func _set_buttons_disabled(disabled: bool) -> void:
	for button in [initButton, sessionButton, programButton, exercisesButton, statsButton, dataButton, settingsButton]:
		button.disabled = disabled


func _set_active_button(active_button: Button) -> void:
	# Get all button nodes
	var buttons = [initButton, sessionButton, programButton, exercisesButton, statsButton, dataButton, settingsButton]

	# Disable toggle mode for all buttons first
	for button in buttons:
		button.disabled = false 

	# Set the active button's toggle mode and press it
	active_button.disabled = true # So that we cant re-enter same menu we are currently in
