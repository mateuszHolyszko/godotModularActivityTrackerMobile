extends Menu

@onready var _sub_menu_container: Container = %SubMenuContainer
@onready var confirm_menu: ConfirmationEntryMenu = %ConfirmationEntryMenu

@onready var mesurment_button: Button = %MesurmentButton
@onready var exercise_entry_button: Button = %ExerciseEntryButton
@onready var session_button: Button = %SessionButton

@onready var input_date_from: DateInputButton = %DateFromInputButton
@onready var input_date_to: DateInputButton = %DateToInputButton

@onready var data_panel: Panel = %DataPanel # holds one of following scenes
var mesurement_data: PackedScene = null
var exercise_entry_data: PackedScene = null
var session_data: PackedScene = null

@onready var batch_size_label: Label = %BatchSizeLabel # displays number of data points in current_data_instance, format: "Batch size:\n{value}"

# Keep reference to the current instance so we can manage it
var current_data_instance: Node = null

func _ready():
	# Load scenes
	mesurement_data = load("res://scenes/dataMenu/mesurment/mesurement_data.tscn")
	exercise_entry_data = load("res://scenes/dataMenu/exerciseEntry/exercise_entry_data.tscn")
	session_data = load("res://scenes/dataMenu/session/session_data.tscn")
	
	mesurment_button.pressed.connect(_on_mesurment_pressed)
	exercise_entry_button.pressed.connect(_on_exercise_entry_pressed)
	session_button.pressed.connect(_on_session_button_pressed)
	
	
	
	# Connect date buttons
	input_date_from.date_confirmed.connect(_on_date_from_confirmed)
	input_date_to.date_confirmed.connect(_on_date_to_confirmed)
	

func _on_mesurment_pressed() -> void:
	exercise_entry_button.disabled = false
	session_button.disabled = false
	
	mesurment_button.disabled = true
	_clear_data_panel()
	_add_scene_to_panel(mesurement_data)
	
	# Update the newly added panel with current date range
	_update_current_panel_dates()

func _on_exercise_entry_pressed() -> void:
	session_button.disabled = false
	mesurment_button.disabled = false
	
	exercise_entry_button.disabled = true
	_clear_data_panel()
	_add_scene_to_panel(exercise_entry_data)
	
	# Update the newly added panel with current date range
	_update_current_panel_dates()

func _on_session_button_pressed() -> void:
	exercise_entry_button.disabled = false
	mesurment_button.disabled = false
	
	session_button.disabled = true
	_clear_data_panel()
	_add_scene_to_panel(session_data)
	
	# Update the newly added panel with current date range
	_update_current_panel_dates()

func _on_date_from_confirmed(new_date: Dictionary) -> void:
	# Convert date dictionary to Unix timestamp
	var from_timestamp = Time.get_unix_time_from_datetime_dict(new_date)
	
	# Update the current data panel's from_time
	current_data_instance.from_time = from_timestamp

func _on_date_to_confirmed(new_date: Dictionary) -> void:
	# Convert date dictionary to Unix timestamp
	var to_timestamp = Time.get_unix_time_from_datetime_dict(new_date)
	
	current_data_instance.to_time = to_timestamp

func _update_current_panel_dates() -> void:
	if current_data_instance == null:
		return
	
	# Get timestamps from date buttons
	var from_date = input_date_from.get_current_date()
	var to_date = input_date_to.get_current_date()
	
	var from_timestamp = Time.get_unix_time_from_datetime_dict(from_date)
	var to_timestamp = Time.get_unix_time_from_datetime_dict(to_date)
	
	# Update the panel's dates
	current_data_instance.from_time = from_timestamp
	current_data_instance.to_time = to_timestamp

func _on_data_loaded(count: int) -> void:
	batch_size_label.text = "Batch size\n" + str(count)

func _clear_data_panel() -> void:
	# Remove all children from data_panel
	for child in data_panel.get_children():
		child.queue_free()
	current_data_instance = null

func _add_scene_to_panel(scene: PackedScene) -> void:
	if scene == null:
		return
	
	# Instantiate the scene
	var instance = scene.instantiate()
	
	# Pass sub menu to it
	instance.sub_menu_container = _sub_menu_container
	
	# Add it as a child of data_panel
	data_panel.add_child(instance)
	
	# Store reference
	current_data_instance = instance
	
	# Connect the data_loaded signal if the instance has it
	if instance.has_signal("data_loaded"):
		instance.data_loaded.connect(_on_data_loaded)
