extends Control

@export var sub_menu_container: Container # use it for pickExBtn, and then pass it further down to workoutExerciseRow export

@onready var pick_exercise_button: PickExerciseButton = %PickExerciseButton # Holds exercise, and allows to switch exercise mid workout
@onready var add_set_button: Button = %AddSetButton # Appends set to exercise

@onready var expand_note_button: Button = %ExpandNoteButton # toggels visisbility of ExpandNotePanel (toggle mode button)
@onready var expand_note_panel: Panel = %ExpandNotePanel # holds inputNoteButton
@onready var input_note_button: TextInputButton = %InputNoteButton

@onready var set_container: VBoxContainer = %SetContainerVB
var _exercise_set_row_scene: PackedScene = null

# Reference to the exercise data this row represents
var exercise_index: int = -1
var exercise_data = null  # WorkoutSession.WorkoutExerciseData

# Flag to track if we've been setup
var _is_setup: bool = false
# Flag to track if _ready has run
var _ready_called: bool = false
# Flag to prevent clearing during initialization
var _is_initializing: bool = false

func _ready():
	_ready_called = true
	
	# Load the workout exercise set row scene once and cache it
	_exercise_set_row_scene = load("res://scenes/sessionMenu/workoutMenu/workoutMenuElements/workoutSetRow.tscn")
	
	# Set buttons container path
	pick_exercise_button.submenu_container_path = sub_menu_container.get_path()
	input_note_button.submenu_container_path = sub_menu_container.get_path()
	
	# Connect signals
	add_set_button.pressed.connect(_on_add_set_pressed)

	# Connect to pick exercise button value change
	pick_exercise_button.value_changed.connect(_on_exercise_changed)
	input_note_button.value_changed.connect(_on_note_changed)

	# Connect note expand button
	expand_note_button.pressed.connect(_on_expand_note_toggled)

	# Initialize note panel as hidden by default
	expand_note_panel.visible = false
	expand_note_button.button_pressed = false

	# Set the toggle mode
	expand_note_button.toggle_mode = true
	
	# If we were already setup, complete the initialization now
	if _is_setup:
		_finish_setup()

func _on_expand_note_toggled():
	"""Toggle the visibility of the expand note panel"""
	expand_note_panel.visible = expand_note_button.button_pressed

func setup(p_exercise_data, p_exercise_index: int) -> void:
	"""Setup the row with exercise data and index"""
	exercise_data = p_exercise_data
	exercise_index = p_exercise_index
	
	# Mark as setup
	_is_setup = true
	
	# If ready already ran, finish setup now
	if _ready_called:
		_finish_setup()

func set_exercise_index(new_index: int) -> void:
	exercise_index = new_index
	for set_index in range(set_container.get_child_count()):
		var set_row = set_container.get_child(set_index)
		set_row.exercise_index = new_index
		set_row.set_index = set_index

func _finish_setup() -> void:
	"""Complete the setup after all nodes are ready"""
	_is_initializing = true
	
	# Update the pick exercise button with the exercise name
	if exercise_data and exercise_data.exercise:
		# Set the text directly without triggering the signal
		pick_exercise_button.text = exercise_data.exercise.name
		# Manually update the value without emitting signal
		pick_exercise_button.current_value = exercise_data.exercise.name
		input_note_button.current_value = exercise_data.note
		
		# Apply muscle color to the pick exercise button
		_update_muscle_color(exercise_data.exercise.name)
	
	# Populate existing sets
	_populate_sets()
	
	# Connect to workout signals for real-time updates
	_connect_to_workout_signals()
	
	_is_initializing = false

func _update_muscle_color(exercise_name: String) -> void:
	"""Update the background color of UI elements based on the exercise's target muscle"""
	# Get the target muscle for this exercise
	var target_muscle = DataManager.ExerciseManager.get_exercise_target_muscle(exercise_name)
	
	# Get the color from MuscleDict
	var muscle_color = MuscleDict.get_color(target_muscle)
	
	# Apply color to pick_exercise_button background only
	if pick_exercise_button:
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = muscle_color
		pick_exercise_button.add_theme_stylebox_override("normal", stylebox)

func _on_note_changed(new_note: String) -> void:
	if _is_initializing or not exercise_data:
		return

	exercise_data.note = new_note
		

func _populate_sets(reset_edit_state: bool = false, reuse_sets: bool = true) -> void:
	"""Create a row for each set in the exercise"""
	if not exercise_data:
		return

	if not reuse_sets:
		for child in set_container.get_children():
			child.free()
	
	# Get sets from exercise data
	var sets = exercise_data.sets
	
	# Reuse existing rows so their local edit state survives data refreshes.
	for set_index in range(sets.size()):
		var set_data = sets[set_index]
		var row: Control
		if reuse_sets and set_index < set_container.get_child_count():
			row = set_container.get_child(set_index)
			row.setup(set_data, exercise_index, set_index, not reset_edit_state)
		else:
			row = _exercise_set_row_scene.instantiate()
			row.sub_menu_container = sub_menu_container
			row.setup(set_data, exercise_index, set_index, false)
			set_container.add_child(row)

	# Remove only rows that no longer have corresponding set data.
	while set_container.get_child_count() > sets.size():
		set_container.get_child(set_container.get_child_count() - 1).queue_free()
		
	# For some reason in scroll it doesnt expand correctly, so adjust manualy
	if sets.size() > 0:
		custom_minimum_size.y = 200 + sets.size() * 250
	else:
		custom_minimum_size.y = 200

func _append_set_row(set_index: int) -> void:
	if not exercise_data or set_index < 0 or set_index >= exercise_data.sets.size():
		return

	var row = _exercise_set_row_scene.instantiate()
	row.sub_menu_container = sub_menu_container
	row.setup(exercise_data.sets[set_index], exercise_index, set_index, false)
	set_container.add_child(row)
	custom_minimum_size.y = 200 + set_container.get_child_count() * 250

func _reindex_set_rows(start_index: int = 0) -> void:
	for index in range(start_index, set_container.get_child_count()):
		var row = set_container.get_child(index)
		row.set_index = index
		row.exercise_index = exercise_index

func _on_add_set_pressed() -> void:
	"""Add a new set to the exercise"""
	if not GlobalElements.CurrentWorkout or not GlobalElements.CurrentWorkout.is_active():
		print("No active workout")
		return
	
	if exercise_index < 0:
		print("No exercise selected")
		return
	
	# Add a new set with default values (0 weight, 0 reps), if its bodyweight exercise 0 means bodyweight
	var default_weight = 0.0
	if GlobalElements.CurrentWorkout.get_exercise_data_at(exercise_index).exercise.bodyweight:
		default_weight = GlobalElements.CurrentWorkout.get_body_weight()
	var default_reps = 0
	
	GlobalElements.CurrentWorkout.add_set_to_exercise(exercise_index, default_weight, default_reps)
	
	# The set_added signal will trigger a refresh

func _on_exercise_changed(new_exercise_name: String) -> void:
	"""Handle exercise change mid-workout via the pick exercise button"""
	# Skip if we're initializing
	if _is_initializing:
		return
	
	if not GlobalElements.CurrentWorkout or not GlobalElements.CurrentWorkout.is_active():
		return
	
	if exercise_index < 0:
		return
	
	# Get the exercise object from the name
	var exercise = DataManager.ExerciseManager.get_exercise(new_exercise_name)
	if not exercise:
		push_error("Exercise '%s' not found" % new_exercise_name)
		return
	
	# Update the exercise data
	if exercise_data:
		exercise_data.exercise = exercise
		exercise_data.note = exercise.note
		input_note_button.current_value = exercise_data.note
		
		# Clear existing sets
		exercise_data.sets.clear()
		
		# Query history for the new exercise and pre-populate sets
		var latest_entry = DataManager.ExerciseEntryManager.get_latest_entry_for_exercise(new_exercise_name)
		if latest_entry:
			var latest_sets = latest_entry.sets
			for set_data in latest_sets:
				var weight = set_data.get("weight", 0.0)
				var reps = set_data.get("reps", 0)
				exercise_data.add_set(weight, reps)
			print("Exercise changed to '%s' - Pre-populated %d sets from history" % [new_exercise_name, latest_sets.size()])
		else:
			print("Exercise changed to '%s' - No history found" % new_exercise_name)
		
		# Refresh the UI
		_populate_sets(true, false)
		
		# Update the muscle color for the new exercise
		_update_muscle_color(new_exercise_name)
		GlobalElements.CurrentWorkout.exercise_updated.emit(exercise_index)

func _connect_to_workout_signals() -> void:
	"""Connect to workout signals to update UI in real-time"""
	if not GlobalElements.CurrentWorkout:
		return
	
	# Disconnect any existing connections to avoid duplicates
	_disconnect_from_workout_signals()
	
	# Connect to set signals
	GlobalElements.CurrentWorkout.set_added.connect(_on_set_added)
	GlobalElements.CurrentWorkout.set_removed.connect(_on_set_removed)
	GlobalElements.CurrentWorkout.set_updated.connect(_on_set_updated)

func _disconnect_from_workout_signals() -> void:
	"""Disconnect from workout signals"""
	if not GlobalElements.CurrentWorkout:
		return
	
	if GlobalElements.CurrentWorkout.set_added.is_connected(_on_set_added):
		GlobalElements.CurrentWorkout.set_added.disconnect(_on_set_added)
	if GlobalElements.CurrentWorkout.set_removed.is_connected(_on_set_removed):
		GlobalElements.CurrentWorkout.set_removed.disconnect(_on_set_removed)
	if GlobalElements.CurrentWorkout.set_updated.is_connected(_on_set_updated):
		GlobalElements.CurrentWorkout.set_updated.disconnect(_on_set_updated)

func _on_set_added(exercise_idx: int, set_index: int) -> void:
	"""Called when a set is added to any exercise"""
	if exercise_idx == exercise_index:
		if set_index != set_container.get_child_count():
			return
		# The model appends the new set, so preserve existing rows and add only it.
		_append_set_row(set_index)

func _on_set_removed(exercise_idx: int, set_index: int) -> void:
	"""Called when a set is removed from any exercise"""
	if exercise_idx == exercise_index:
		if set_index >= 0 and set_index < set_container.get_child_count():
			set_container.get_child(set_index).free()
			_reindex_set_rows(set_index)
			custom_minimum_size.y = 200 + set_container.get_child_count() * 250

func _on_set_updated(exercise_idx: int, set_index: int) -> void:
	"""Called when a set is updated in any exercise"""
	if exercise_idx == exercise_index:
		# Update the specific set row without rebuilding all
		if set_index < set_container.get_child_count():
			var row = set_container.get_child(set_index)
			if row and row.has_method("refresh"):
				row.refresh()

func refresh() -> void:
	"""Manually refresh the row"""
	_populate_sets(false)

""" DO NOT USE _exit_tree in persistent menus
# Clean up signals when the node is removed
func _exit_tree() -> void:
	_disconnect_from_workout_signals()
"""
