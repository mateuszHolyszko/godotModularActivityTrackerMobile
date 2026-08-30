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
var session_data_point_scene: PackedScene = null

var sub_menu_container: Container = null 
@onready var filter_program_button: OptionInputButton = %FilterProgramButton
@onready var filter_orphans_button: Button = %FilterOrphansButton

var data_points: Array = []
var _current_filter_program: String = ""  # Track current program filter
var _current_filter_mode: String = "none"  # "none", "program", "orphans"

func _ready():
	session_data_point_scene = load("res://scenes/dataMenu/session/session_data_point_panel.tscn")
	
	filter_program_button.submenu_container_path = sub_menu_container.get_path()
	
	# Connect filter signals
	filter_program_button.value_changed.connect(_on_program_filter_changed)
	filter_orphans_button.pressed.connect(_on_orphans_filter_toggled)
	
	# Set initial state for orphans button
	filter_orphans_button.toggle_mode = true
	filter_orphans_button.button_pressed = false
	
	# load programs as options
	filter_program_button.set_options_data( DataManager.ProgramManager.get_all_program_names() )
	
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

# Load data from DataManager
func _load_data() -> void:
	# Clear existing data points
	_clear_data_points()
	
	# Query data from DataManager
	if from_time > 0 and to_time > 0:
		var raw_data = DataManager.SessionManager.get_sessions_in_range(from_time, to_time)
		
		# Apply filters based on current mode
		var filtered_data = _apply_filters(raw_data)
		data_points = filtered_data
		
		# Create UI elements for each data point
		for data_point in data_points:
			_add_data_point(data_point["session"])
	
	# Emit signal with the count of loaded data points
	emit_signal("data_loaded", data_points.size())

# Apply filters to the raw data
func _apply_filters(raw_data: Array) -> Array:
	var filtered = []
	
	for data_item in raw_data:
		var session = data_item["session"]
		var should_include = true
		
		match _current_filter_mode:
			"program":
				# Filter by program name
				if _current_filter_program != "" and session.program:
					should_include = session.program.program_name == _current_filter_program
				else:
					should_include = false
					
			"orphans":
				# Filter orphans (sessions with null program)
				should_include = session.program == null
				
			"none":
				# No filter applied
				should_include = true
		
		if should_include:
			filtered.append(data_item)
	
	return filtered

# Clear all existing data point children
func _clear_data_points() -> void:
	for child in data_container.get_children():
		child.queue_free()

# Add a single data point to the container
func _add_data_point(data_point: Session) -> void:
	if session_data_point_scene == null:
		return
	
	var instance = session_data_point_scene.instantiate()
	instance.set_data(data_point)
	data_container.add_child(instance)

# Refresh data without changing time range
func refresh_data() -> void:
	_load_data()

# Get current data points
func get_data_points() -> Array:
	return data_points

# Filter handlers
func _on_program_filter_changed(program_name: String) -> void:
	# Clear orphans filter if active
	if _current_filter_mode == "orphans":
		filter_orphans_button.button_pressed = false
	
	# Set program filter
	if program_name != "" and program_name != "--":
		_current_filter_program = program_name
		_current_filter_mode = "program"
	else:
		# Clear program filter if "clear" was selected
		_current_filter_program = ""
		_current_filter_mode = "none"
	
	# Reload data with new filters
	_load_data()

func _on_orphans_filter_toggled() -> void:
	if filter_orphans_button.button_pressed:
		# Enable orphans filter
		_current_filter_mode = "orphans"
		
		# Clear program filter if active
		if _current_filter_program != "":
			_current_filter_program = ""
			filter_program_button.current_value = null  # Reset program picker
	else:
		# Disable orphans filter
		_current_filter_mode = "none"
	
	# Reload data with new filters
	_load_data()

# Optional: Add a method to clear all filters
func clear_filters() -> void:
	_current_filter_mode = "none"
	_current_filter_program = ""
	filter_program_button.current_value = null
	filter_orphans_button.button_pressed = false
	_load_data()

# Optional: Check if any filter is active
func has_active_filter() -> bool:
	return _current_filter_mode != "none"

# Optional: Get current filter description
func get_filter_description() -> String:
	match _current_filter_mode:
		"program":
			return "Filtered by program: %s" % _current_filter_program
		"orphans":
			return "Showing sessions without a program (orphans)"
		_:
			return "No filters applied"
