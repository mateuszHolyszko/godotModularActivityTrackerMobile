extends VBoxContainer

signal data_loaded(count: int)

@export var from_time: int:
	set(value):
		from_time = value
		_load_data()

@export var to_time: int:
	set(value):
		to_time = value
		_load_data()

@onready var data_container: HFlowContainer = %DataContainer
var exercise_entry_data_point_scene: PackedScene = null

var sub_menu_container: Container = null 
@onready var filter_exercise_pick_button: PickExerciseButton = %FilterExercisePickButton
@onready var program_input_button: OptionInputButton = %ProgramInputButton
@onready var filter_orphans_button: Button = %FilterOrphansButton

var data_points: Array = []
var _current_filter_exercise: String = ""  # Track current exercise filter
var _current_filter_program: String = ""   # Track current program filter
var _filter_orphans: bool = false          # Track orphans filter state

func _ready():
	exercise_entry_data_point_scene = load("res://scenes/dataMenu/exerciseEntry/exercise_entry_data_point_panel.tscn")
	
	filter_exercise_pick_button.submenu_container_path = sub_menu_container.get_path()
	program_input_button.submenu_container_path = sub_menu_container.get_path()
	
	# Connect filter signals
	filter_exercise_pick_button.value_changed.connect(_on_exercise_filter_changed)
	program_input_button.value_changed.connect(_on_program_filter_changed)
	filter_orphans_button.pressed.connect(_on_orphans_filter_toggled)
	
	# Get programs
	var program_names = DataManager.ProgramManager.get_all_program_names()
	program_input_button.set_options_data(program_names)
	
	# Set initial state for orphans button
	filter_orphans_button.toggle_mode = true
	filter_orphans_button.button_pressed = false
	
	# set init from time and to time
	if from_time == 0:
		from_time = _get_week_ago_timestamp()  # week by default
	if to_time == 0:
		to_time = _get_current_timestamp()     # now by default
	
	# Load initial data
	_load_data()

# Helper functions to get timestamps
func _get_current_timestamp() -> int:
	return Time.get_unix_time_from_system()

func _get_week_ago_timestamp() -> int:
	return _get_current_timestamp() - (7 * 24 * 60 * 60)  # 7 days in seconds

# Helper function to get program from session
func _get_program_from_entry(entry: ExerciseEntry) -> String:
	if entry.session_id == "":
		return ""
	
	var session = DataManager.SessionManager.get_session_by_id(entry.session_id)
	if session and session.program:
		return session.program.program_name
	
	return ""

# Load data from DataManager
func _load_data() -> void:
	# Clear existing data points
	_clear_data_points()
	
	# Query data from DataManager
	if from_time > 0 and to_time > 0:
		var raw_data = DataManager.ExerciseEntryManager.get_entries_in_range(from_time, to_time)
		
		# Apply filters based on current mode
		var filtered_data = _apply_filters(raw_data)
		data_points = filtered_data
		
		# Create UI elements for each data point
		for data_point in data_points:
			_add_data_point(data_point["entry"])
			
		# Emit signal with the count of loaded data points
		emit_signal("data_loaded", data_points.size())

# Apply filters to the raw data
func _apply_filters(raw_data: Array) -> Array:
	var filtered = []
	
	for data_item in raw_data:
		var entry = data_item["entry"]
		var should_include = true
		
		# Check if orphans filter is active
		if _filter_orphans:
			# Filter orphans (entries with null exercise OR no program)
			var has_exercise = entry.exercise != null
			var program_name = _get_program_from_entry(entry)
			var has_program = program_name != ""
			should_include = not has_exercise or not has_program
		
		# Apply exercise filter if active
		if should_include and _current_filter_exercise != "":
			if entry.exercise:
				should_include = entry.exercise.name == _current_filter_exercise
			else:
				should_include = false
		
		# Apply program filter if active
		if should_include and _current_filter_program != "":
			var program_name = _get_program_from_entry(entry)
			should_include = program_name == _current_filter_program
		
		if should_include:
			filtered.append(data_item)
	
	return filtered

# Clear all existing data point children
func _clear_data_points() -> void:
	for child in data_container.get_children():
		child.queue_free()

# Add a single data point to the container
func _add_data_point(data_point: ExerciseEntry) -> void:
	if exercise_entry_data_point_scene == null:
		return
	
	var instance = exercise_entry_data_point_scene.instantiate()
	instance.set_data(data_point)
	data_container.add_child(instance)

# Refresh data without changing time range
func refresh_data() -> void:
	_load_data()

# Get current data points
func get_data_points() -> Array:
	return data_points

# Filter handlers
func _on_exercise_filter_changed(exercise_name: String) -> void:
	# Clear exercise filter
	if exercise_name != "" and exercise_name != "--":
		_current_filter_exercise = exercise_name
	else:
		_current_filter_exercise = ""
	
	# If orphans is active, clear it since we're applying a regular filter
	if _filter_orphans and _current_filter_exercise != "":
		filter_orphans_button.button_pressed = false
		_filter_orphans = false
	
	# Reload data with new filters
	_load_data()

func _on_program_filter_changed(program_name: String) -> void:
	# Clear program filter
	if program_name != "" and program_name != "--":
		_current_filter_program = program_name
	else:
		_current_filter_program = ""
	
	# If orphans is active, clear it since we're applying a regular filter
	if _filter_orphans and _current_filter_program != "":
		filter_orphans_button.button_pressed = false
		_filter_orphans = false
	
	# Reload data with new filters
	_load_data()

func _on_orphans_filter_toggled() -> void:
	if filter_orphans_button.button_pressed:
		# Enable orphans filter
		_filter_orphans = true
		
		# Clear exercise and program filters when orphans is enabled
		_current_filter_exercise = ""
		_current_filter_program = ""
		filter_exercise_pick_button.current_value = null
		program_input_button.current_value = null
	else:
		# Disable orphans filter
		_filter_orphans = false
	
	# Reload data with new filters
	_load_data()

# Optional: Add a method to clear all filters
func clear_filters() -> void:
	_filter_orphans = false
	_current_filter_exercise = ""
	_current_filter_program = ""
	filter_exercise_pick_button.current_value = null
	program_input_button.current_value = null
	filter_orphans_button.button_pressed = false
	_load_data()

# Optional: Check if any filter is active
func has_active_filter() -> bool:
	return _filter_orphans or _current_filter_exercise != "" or _current_filter_program != ""

# Optional: Get filter description
func get_filter_description() -> String:
	var filters = []
	if _current_filter_exercise != "":
		filters.append("Exercise: %s" % _current_filter_exercise)
	if _current_filter_program != "":
		filters.append("Program: %s" % _current_filter_program)
	if _filter_orphans:
		filters.append("Orphans (no exercise or program)")
	
	if filters.is_empty():
		return "No filters applied"
	
	return "Filters: " + ", ".join(filters)
