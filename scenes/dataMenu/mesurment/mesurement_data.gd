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
var mesurement_data_point_scene: PackedScene = null

var sub_menu_container: Container = null 
@onready var type_input_button: OptionInputButton = %TypeInputButton

var data_points: Array = []
var _current_filter_type: String = ""  # Track current measurement type filter
var _filter_active: bool = false

func _ready():
	mesurement_data_point_scene = load("res://scenes/dataMenu/mesurment/mesurement_data_point_panel.tscn")
	
	type_input_button.submenu_container_path = sub_menu_container.get_path()
	
	# Connect filter signal
	type_input_button.value_changed.connect(_on_type_filter_changed)
	
	# Set up measurement type options
	type_input_button.set_options_data(MuscleDict.get_all_measurements())
	
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
		var raw_data = DataManager.MeasurementManager.query_measurements(from_time, to_time)
		
		# Apply filter based on current selection
		var filtered_data = _apply_filters(raw_data)
		data_points = filtered_data
		
		# Create UI elements for each data point
		for data_point in data_points:
			_add_data_point(data_point)
			
		# Emit signal with the count of loaded data points
		emit_signal("data_loaded", data_points.size())

# Apply filters to the raw data
func _apply_filters(raw_data: Array) -> Array:
	# If no filter is active, return all data
	if not _filter_active or _current_filter_type == "":
		return raw_data
	
	var filtered = []
	for data_point in raw_data:
		# Filter by measurement type
		if data_point is MeasurementEntry:
			if data_point.type == _current_filter_type:
				filtered.append(data_point)
		elif data_point is Dictionary:
			# Handle dictionary format if needed
			if data_point.get("type", "") == _current_filter_type:
				filtered.append(data_point)
	
	return filtered

# Clear all existing data point children
func _clear_data_points() -> void:
	for child in data_container.get_children():
		child.queue_free()

# Add a single data point to the container
func _add_data_point(data_point: MeasurementEntry) -> void:
	if mesurement_data_point_scene == null:
		return
	
	var instance = mesurement_data_point_scene.instantiate()
	instance.set_data(data_point)
	data_container.add_child(instance)

# Refresh data without changing time range
func refresh_data() -> void:
	_load_data()

# Get current data points
func get_data_points() -> Array:
	return data_points

# Filter handlers
func _on_type_filter_changed(type_name) -> void:
	#print(type_name)
	# Check if the selection is a valid filter or clear
	if type_name != null and type_name != "" and type_name != "--":
		_current_filter_type = type_name
		_filter_active = true
	else:
		# Clear filter - this handles deselecting (when "--" is returned)
		_current_filter_type = ""
		_filter_active = false
	
	# Reload data with new filter
	_load_data()

# Optional: Clear the filter programmatically
func clear_filter() -> void:
	_current_filter_type = ""
	_filter_active = false
	type_input_button.current_value = null
	_load_data()

# Optional: Check if filter is active
func is_filter_active() -> bool:
	return _filter_active

# Optional: Get current filter value
func get_current_filter() -> String:
	return _current_filter_type

# Optional: Get filter description
func get_filter_description() -> String:
	if _filter_active and _current_filter_type != "":
		return "Filtered by measurement type: %s" % _current_filter_type
	return "No filter applied"
