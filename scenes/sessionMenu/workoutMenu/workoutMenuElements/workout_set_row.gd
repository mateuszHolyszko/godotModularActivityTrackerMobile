extends Control

@export var sub_menu_container: Container 

@onready var set_number_label: Label = %SetNumber

@onready var input_weight_button: NumericInputButton = %InputWeightButton
@onready var input_reps_button: NumericInputButton = %RepsWeightButton

# References to parent data
var exercise_index: int = -1
var set_index: int = -1
var set_data: Dictionary = {}  # {order: int, weight: float, reps: int}

# Flag to track if we've been setup
var _is_setup: bool = false
# Flag to track if _ready has run
var _ready_called: bool = false

func _ready():
	_ready_called = true
	
	# Set up numeric input buttons
	input_weight_button.submenu_container_path = sub_menu_container.get_path()
	input_reps_button.submenu_container_path = sub_menu_container.get_path()
	
	# Connect value changed signals
	input_weight_button.value_changed.connect(_on_weight_changed)
	input_reps_button.value_changed.connect(_on_reps_changed)
	
	# If we were already setup, complete the initialization now
	if _is_setup:
		_finish_setup()

func setup(p_set_data: Dictionary, p_exercise_index: int, p_set_index: int) -> void:
	"""Setup the row with set data, exercise index, and set index"""
	set_data = p_set_data
	exercise_index = p_exercise_index
	set_index = p_set_index
	
	# Mark as setup
	_is_setup = true
	
	# If ready already ran, finish setup now
	if _ready_called:
		_finish_setup()

func _finish_setup() -> void:
	"""Complete the setup after all nodes are ready"""
	# Update the set number label
	set_number_label.text = str(set_index + 1)
	
	# Set initial values from the set data
	if set_data and set_data.has("weight"):
		input_weight_button.current_value = set_data.get("weight", 0.0)
	
	if set_data and set_data.has("reps"):
		input_reps_button.current_value = set_data.get("reps", 0)

func _on_weight_changed(new_weight: float) -> void:
	"""Handle weight value change"""
	if not GlobalElements.CurrentWorkout or not GlobalElements.CurrentWorkout.is_active():
		return
	
	if exercise_index < 0 or set_index < 0:
		return
	
	# Update the workout session data
	var success = GlobalElements.CurrentWorkout.update_set(
		exercise_index,
		set_index,
		new_weight,
		input_reps_button.current_value
	)
	
	if not success:
		push_error("Failed to update set weight")

func _on_reps_changed(new_reps: float) -> void:
	"""Handle reps value change"""
	if not GlobalElements.CurrentWorkout or not GlobalElements.CurrentWorkout.is_active():
		return
	
	if exercise_index < 0 or set_index < 0:
		return
	
	# Update the workout session data
	var success = GlobalElements.CurrentWorkout.update_set(
		exercise_index,
		set_index,
		input_weight_button.current_value,
		int(new_reps)  # Convert to int for reps
	)
	
	if not success:
		push_error("Failed to update set reps")

func refresh() -> void:
	"""Manually refresh the set values from the workout data"""
	if not GlobalElements.CurrentWorkout or not GlobalElements.CurrentWorkout.is_active():
		return
	
	if exercise_index < 0 or set_index < 0:
		return
	
	# Get the updated set data from the workout
	var exercise_data = GlobalElements.CurrentWorkout.get_exercise_data_at(exercise_index)
	if not exercise_data:
		return
	
	var sets = exercise_data.sets
	if set_index >= sets.size():
		return
	
	var updated_set_data = sets[set_index]
	if updated_set_data:
		set_data = updated_set_data
		input_weight_button.current_value = set_data.get("weight", 0.0)
		input_reps_button.current_value = set_data.get("reps", 0)

func _exit_tree() -> void:
	"""Clean up when the node is removed"""
	# Disconnect signals
	if input_weight_button.value_changed.is_connected(_on_weight_changed):
		input_weight_button.value_changed.disconnect(_on_weight_changed)
	if input_reps_button.value_changed.is_connected(_on_reps_changed):
		input_reps_button.value_changed.disconnect(_on_reps_changed)
