extends Menu

@onready var sub_menu_container: Container = %SubMenuContainer # pass it to workoutExerciseRow export
@onready var sub_menu_container_ex_picker: Container = %SubMenuContainerExercisePicker # for exercise picker, since it will be used alongside InsertPositionInput


@onready var exercises_container: VBoxContainer = %ScrollContent 

@onready var abort_button: Button = %AbortButton
@onready var finish_button: Button = %FinishButton
@onready var back_button: Button = %BackButton # Initially hidden 
@onready var CRUDE_HB: HBoxContainer = %CRUDE_HB # contains buttons above

@onready var insert_exercise_position: InsertPositionInput = %InsertPositionInput

@onready var confirm_dialog: ConfirmationEntryMenu = %ConfirmationEntryMenu

var _exercise_row_scene: PackedScene = null
var _insert_position: int = -1
var _exercise_picker: PickExerciseEntry = null

func _ready():
	#is_persistent = true # Set to be persisent menu
	# Load the workout exercise row scene once and cache it
	_exercise_row_scene = load("res://scenes/sessionMenu/workoutMenu/workoutMenuElements/workoutExerciseRow.tscn")
	
	_connect_to_workout_signals()
	
	# Populate exercises from current workout
	_populate_exercises()
	
	# Connect button signals
	abort_button.pressed.connect(_on_abort_pressed)
	finish_button.pressed.connect(_on_finish_pressed)
	back_button.pressed.connect(_on_back_pressed)
	insert_exercise_position.value_changed.connect(_on_insert_position_selected)
	
	#GlobalElements.CurrentWorkout.print_summary()

func _populate_exercises() -> void:
	# Clear existing exercises (keep any template children if needed)
	for child in exercises_container.get_children():
		child.free()
	
	# Check if there's an active workout
	if not GlobalElements.CurrentWorkout or not GlobalElements.CurrentWorkout.is_active():
		insert_exercise_position.set_options_data([])
		print("No active workout found")
		return
	
	_update_insert_position_options()
	
	# Get exercise data from the current workout
	var exercise_count = GlobalElements.CurrentWorkout.get_exercise_count()
	
	# Create a row for each exercise
	for i in range(exercise_count):
		var exercise_data = GlobalElements.CurrentWorkout.get_exercise_data_at(i)
		if exercise_data:
			var row = _exercise_row_scene.instantiate()
			
			# Set the sub_menu_container for pick exercise button
			row.sub_menu_container = sub_menu_container
			
			# Pass the exercise data and index to the row
			row.setup(exercise_data, i)
			
			exercises_container.add_child(row)

func _update_insert_position_options() -> void:
	var exercise_names: Array[String] = []
	if GlobalElements.CurrentWorkout and GlobalElements.CurrentWorkout.is_active():
		var exercise_count = GlobalElements.CurrentWorkout.get_exercise_count()
		for i in range(exercise_count):
			var exercise_data = GlobalElements.CurrentWorkout.get_exercise_data_at(i)
			if exercise_data and exercise_data.exercise:
				exercise_names.append(exercise_data.exercise.name)
	insert_exercise_position.set_options_data(exercise_names)

func _on_exercise_updated(_exercise_index: int) -> void:
	_update_insert_position_options()

""" DO NOT USE _exit_tree in persistent menus
func _exit_tree() -> void:
	var workout = GlobalElements.CurrentWorkout
	if not workout:
		return

	if workout.exercise_added.is_connected(_on_exercise_added):
		workout.exercise_added.disconnect(_on_exercise_added)
	if workout.exercise_removed.is_connected(_on_exercise_removed):
		workout.exercise_removed.disconnect(_on_exercise_removed)
	if workout.exercise_updated.is_connected(_on_exercise_updated):
		workout.exercise_updated.disconnect(_on_exercise_updated)
"""

func _on_exercise_added(index: int) -> void:
	var workout = GlobalElements.CurrentWorkout
	if not workout or index < 0 or index >= workout.get_exercise_count():
		return

	var exercise_data = workout.get_exercise_data_at(index)
	if not exercise_data:
		return

	var row = _exercise_row_scene.instantiate()
	row.sub_menu_container = sub_menu_container
	row.setup(exercise_data, index)
	exercises_container.add_child(row)
	exercises_container.move_child(row, index)
	_reindex_exercise_rows(index)
	_update_insert_position_options()

func _on_exercise_removed(index: int) -> void:
	if index < 0 or index >= exercises_container.get_child_count():
		return

	exercises_container.get_child(index).free()
	_reindex_exercise_rows(index)
	_update_insert_position_options()

func _reindex_exercise_rows(start_index: int = 0) -> void:
	for index in range(start_index, exercises_container.get_child_count()):
		var row = exercises_container.get_child(index)
		if row.has_method("set_exercise_index"):
			row.set_exercise_index(index)

func _connect_to_workout_signals() -> void:
	var workout = GlobalElements.CurrentWorkout
	if not workout:
		return

	if not workout.exercise_added.is_connected(_on_exercise_added):
		workout.exercise_added.connect(_on_exercise_added)
	if not workout.exercise_removed.is_connected(_on_exercise_removed):
		workout.exercise_removed.connect(_on_exercise_removed)
	if not workout.exercise_updated.is_connected(_on_exercise_updated):
		workout.exercise_updated.connect(_on_exercise_updated)

func _on_insert_position_selected(index: int) -> void:
	_insert_position = index
	_open_exercise_picker()

func _open_exercise_picker() -> void:
	if _exercise_picker:
		return

	var scene := load("res://elements/pickExercise/PickExerciseEntry.tscn")
	if scene == null:
		push_error("WorkoutMenu: failed to load exercise picker scene.")
		return

	_exercise_picker = scene.instantiate()
	_exercise_picker.set_picker_data(DataManager.ExerciseManager, "Select exercise to insert")
	_exercise_picker.exercise_selected.connect(_on_exercise_selected_for_insert)

	var submenu_key := "insert_exercise_picker_%d" % get_instance_id()
	add_submenu(submenu_key, _exercise_picker)
	open_submenu(submenu_key, sub_menu_container_ex_picker)

func _on_exercise_selected_for_insert(exercise_name) -> void:
	if exercise_name == null:
		_close_exercise_picker()
		return

	var exercise = DataManager.ExerciseManager.get_exercise(exercise_name)
	if not exercise:
		push_error("Exercise '%s' not found" % exercise_name)
		_close_exercise_picker()
		return

	if GlobalElements.CurrentWorkout and GlobalElements.CurrentWorkout.insert_exercise_at(_insert_position, exercise) >= 0:
		_close_exercise_picker()
	else:
		_close_exercise_picker()

func _close_exercise_picker() -> void:
	if not is_instance_valid(_exercise_picker):
		_exercise_picker = null
		_insert_position = -1
		return

	_exercise_picker.request_close()
	remove_submenu("insert_exercise_picker_%d" % get_instance_id())
	_exercise_picker.queue_free()
	_exercise_picker = null
	_insert_position = -1

func _on_abort_pressed() -> void:
	confirm_dialog.request_confirmation(
			"Are you sure you want to abort this session?",
			_on_abort_confirmed
		)

func _on_abort_confirmed() -> void:
	# Cancel the current workout
	if GlobalElements.CurrentWorkout and GlobalElements.CurrentWorkout.is_active():
		GlobalElements.CurrentWorkout.cancel_workout()
		print("Workout aborted")
	
	# Clean up the workout reference
	GlobalElements.null_current_workout()
	
	_hide_all_except_back() # Hides all CRUDE elements (Abort and Finish btn) and shows back button
	
	NotificationManager.info("Session successfully aborted")
	
	# Optional: Navigate back or show confirmation
	# get_parent().go_back()  # or whatever navigation you use

func _remove_unedited_sets() -> void:
	var sets_to_remove: Array[Dictionary] = []

	for exercise_row in exercises_container.get_children():
		if not exercise_row.has_method("_populate_sets"):
			continue
		exercise_row._disconnect_from_workout_signals()

		for set_row in exercise_row.set_container.get_children():
			if not set_row.is_edited:
				sets_to_remove.append({
					"exercise_index": exercise_row.exercise_index,
					"set_index": set_row.set_index
				})

	sets_to_remove.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		if first["exercise_index"] == second["exercise_index"]:
			return first["set_index"] > second["set_index"]
		return first["exercise_index"] > second["exercise_index"]
	)

	for set_to_remove in sets_to_remove:
		GlobalElements.CurrentWorkout.remove_set_from_exercise(
			set_to_remove["exercise_index"],
			set_to_remove["set_index"]
		)

func _on_finish_pressed() -> void:
	confirm_dialog.request_confirmation(
				"Are you sure?",
				_on_finish_confirmed
			)

func _on_finish_confirmed() -> void:
	if not GlobalElements.CurrentWorkout or not GlobalElements.CurrentWorkout.is_active():
		print("No active workout to finish")
		return

	_remove_unedited_sets()

	GlobalElements.CurrentWorkout.print_summary()
	# End the workout
	GlobalElements.CurrentWorkout.end_workout()

	# Save the workout to persistent storage
	var session = GlobalElements.CurrentWorkout.save_to_session(
		DataManager.ExerciseManager,
		DataManager.ExerciseEntryManager,
		DataManager.SessionManager
	)

	if session:
		print("Workout finished and saved! Session ID: ", session.session_id)
	else:
		print("Failed to save workout")
	
	# Clean up the workout reference
	GlobalElements.null_current_workout()
	
	_hide_all_except_back() # Hides all CRUDE elements (Abort and Finish btn) and shows back button
	
	NotificationManager.success("Session successfully finished")
	
	# Optional: Navigate away or show completion screen
	# get_parent().show_completion_summary(session)  # or whatever you want to do

func _hide_all_except_back() -> void:
	for child in CRUDE_HB.get_children():
		child.hide()
	
	back_button.show()

func _on_back_pressed() -> void:
	request_close() #dont request close
	#close()

# Optional: Refresh the exercise list if needed
func refresh_exercises() -> void:
	_populate_exercises()
