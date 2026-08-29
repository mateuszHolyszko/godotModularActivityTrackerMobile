extends VBoxContainer

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

var data_points: Array = []

func _ready():
	exercise_entry_data_point_scene = load("res://scenes/dataMenu/exerciseEntry/exercise_entry_data_point_panel.tscn")
	
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
		data_points = DataManager.ExerciseEntryManager.get_entries_in_range(from_time, to_time)
		
		# Create UI elements for each data point
		for data_point in data_points:
			_add_data_point(data_point["entry"])

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
