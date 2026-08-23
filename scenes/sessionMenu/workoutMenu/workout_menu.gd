extends Menu

@onready var sub_menu_container: Container = %SubMenuContainer # pass it to workoutExerciseRow export

@onready var exercises_container: VBoxContainer = %ScrollContent 

@onready var abort_button: Button = %AbortButton
@onready var finish_button: Button = %FinishButton

var _exercise_row_scene: PackedScene = null

func _ready():
	# Load the workout exercise row scene once and cache it
	_exercise_row_scene = load("res://scenes/sessionMenu/workoutMenu/workoutMenuElements/workoutExerciseRow.tscn")
	
	# Populate exercises from current workout
	_populate_exercises()
	
	# Connect button signals
	abort_button.pressed.connect(_on_abort_pressed)
	finish_button.pressed.connect(_on_finish_pressed)

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
	# Cancel the current workout
	if GlobalElements.CurrentWorkout and GlobalElements.CurrentWorkout.is_active():
		GlobalElements.CurrentWorkout.cancel_workout()
		print("Workout aborted")
	
	# Clean up the workout reference
	GlobalElements.CurrentWorkout = null
	
	# Optional: Navigate back or show confirmation
	# get_parent().go_back()  # or whatever navigation you use

func _on_finish_pressed() -> void:
	# End the current workout
	if not GlobalElements.CurrentWorkout or not GlobalElements.CurrentWorkout.is_active():
		print("No active workout to finish")
		return
	
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
	GlobalElements.CurrentWorkout = null
	
	# Optional: Navigate away or show completion screen
	# get_parent().show_completion_summary(session)  # or whatever you want to do

# Optional: Refresh the exercise list if needed
func refresh_exercises() -> void:
	_populate_exercises()
