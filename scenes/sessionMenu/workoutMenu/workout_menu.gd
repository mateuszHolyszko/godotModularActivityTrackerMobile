extends Menu

@onready var sub_menu_container: Container = %SubMenuContainer # pass it to workoutExerciseRow export

@onready var exercises_container: VBoxContainer = %ScrollContent 

@onready var abort_button: Button = %AbortButton
@onready var finish_button: Button = %FinishButton

@onready var confirm_dialog: ConfirmationEntryMenu = %ConfirmationEntryMenu

var _exercise_row_scene: PackedScene = null

func _ready():
	# Load the workout exercise row scene once and cache it
	_exercise_row_scene = load("res://scenes/sessionMenu/workoutMenu/workoutMenuElements/workoutExerciseRow.tscn")
	
	# Populate exercises from current workout
	_populate_exercises()
	
	# Connect button signals
	abort_button.pressed.connect(_on_abort_pressed)
	finish_button.pressed.connect(_on_finish_pressed)
	
	#GlobalElements.CurrentWorkout.print_summary()

func _populate_exercises() -> void:
	# Clear existing exercises (keep any template children if needed)
	for child in exercises_container.get_children():
		child.queue_free()
	
	# Check if there's an active workout
	if not GlobalElements.CurrentWorkout or not GlobalElements.CurrentWorkout.is_active():
		print("No active workout found")
		return
	
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
	
	# Disable finish and abort buttons
	abort_button.disabled = true
	finish_button.disabled = true
	
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
	
	# Disable finish and abort buttons
	abort_button.disabled = true
	finish_button.disabled = true
	
	NotificationManager.success("Session successfully finished")
	
	# Optional: Navigate away or show completion screen
	# get_parent().show_completion_summary(session)  # or whatever you want to do

# Optional: Refresh the exercise list if needed
func refresh_exercises() -> void:
	_populate_exercises()
