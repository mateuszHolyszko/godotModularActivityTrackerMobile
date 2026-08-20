extends Menu

@onready var add_exercise_button: Button = %AddExerciseButton
@onready var scroll_content: VBoxContainer = %ScrollContent
@onready var input_container: Container = %SubMenuInputContainer

@onready var input_filter_target: OptionInputButton = %InputOptionTarget
@onready var input_filter_bodyweight: OptionInputButton = %InputOptionBodyweight

var exercise_manager: ExerciseManager
var exercise_row_scene: PackedScene = null

var current_filters: Dictionary = {
	"target_muscle": "",
	"bodyweight": ""
}

func _ready():
	exercise_manager = DataManager.ExerciseManager
	
	# Load the exercise row scene once and cache it
	exercise_row_scene = load("res://scenes/dataMenu/exerciseRow/exerciseRow.tscn")
	
	add_exercise_button.pressed.connect(_on_add_exercise_pressed)
	
	# Connect filter signals
	if input_filter_target:
		input_filter_target.value_changed.connect(_on_filter_changed)
	if input_filter_bodyweight:
		input_filter_bodyweight.value_changed.connect(_on_filter_changed)
	
	# Load all existing exercises
	_load_all_exercises()


func _create_exercise_row(exercise: Exercise, file_name: String = ""):
	"""
	Create an exercise row and populate it with the exercise data.
	"""
	if not exercise_row_scene:
		return
	
	var exercise_row = exercise_row_scene.instantiate()
	exercise_row.input_elements_container = input_container
	
	# Set the exercise data using the set_exercise method
	exercise_row.set_exercise(exercise, file_name)
	
	# Add to the scroll container
	scroll_content.add_child(exercise_row)

func _on_filter_changed(value):
	"""
	Called when either filter changes. Updates the displayed exercises.
	"""
	# Update current filters
	current_filters["target_muscle"] = input_filter_target.current_value if input_filter_target else ""
	current_filters["bodyweight"] = input_filter_bodyweight.current_value if input_filter_bodyweight else ""
	
	# Re-apply filters
	_apply_filters()

func _apply_filters():
	"""
	Apply the current filters and refresh the exercise list.
	"""
	if not exercise_manager:
		push_error("ExerciseManager not available!")
		return
	
	# Clear all existing exercise rows
	_clear_exercise_rows()
	
	# Get the target muscle filter value
	var target_muscle = current_filters.get("target_muscle", "")
	var bodyweight_filter = current_filters.get("bodyweight", "")
	
	# Check if filters are active - handle null values properly
	var has_target_filter = target_muscle != null and target_muscle != "" and target_muscle != "None" and target_muscle != "All"
	var has_bodyweight_filter = bodyweight_filter != null and bodyweight_filter != "" and bodyweight_filter != "All"
	
	# Get filtered exercises
	var exercises_to_display = []
	
	if has_target_filter and not has_bodyweight_filter:
		# Filter by target muscle only
		var filtered_items = exercise_manager.get_exercises_for_target(target_muscle)
		for item in filtered_items:
			var exercise = item.get("exercise")
			var file_name = item.get("file_name", "")
			if exercise:
				exercises_to_display.append({"exercise": exercise, "file_name": file_name})
				
	elif not has_target_filter and has_bodyweight_filter:
		# Filter by bodyweight only
		var all_items = exercise_manager.get_exercises()
		var is_bodyweight = bodyweight_filter == "Yes"
		for item in all_items:
			var exercise = item.get("exercise")
			var file_name = item.get("file_name", "")
			if exercise and exercise.bodyweight == is_bodyweight:
				exercises_to_display.append({"exercise": exercise, "file_name": file_name})
				
	elif has_target_filter and has_bodyweight_filter:
		# Filter by both target muscle and bodyweight
		var filtered_items = exercise_manager.get_exercises_for_target(target_muscle)
		var is_bodyweight = bodyweight_filter == "Yes"
		for item in filtered_items:
			var exercise = item.get("exercise")
			var file_name = item.get("file_name", "")
			if exercise and exercise.bodyweight == is_bodyweight:
				exercises_to_display.append({"exercise": exercise, "file_name": file_name})
	else:
		# No filters active - show all exercises
		var all_items = exercise_manager.get_exercises()
		for item in all_items:
			var exercise = item.get("exercise")
			var file_name = item.get("file_name", "")
			if exercise:
				exercises_to_display.append({"exercise": exercise, "file_name": file_name})
	
	# Create rows for each exercise
	for exercise_data in exercises_to_display:
		_create_exercise_row(exercise_data["exercise"], exercise_data["file_name"])
	
	print("Displayed %d exercise(s) with filters: target='%s', bodyweight='%s'" % [exercises_to_display.size(), target_muscle, bodyweight_filter])

func _clear_exercise_rows():
	"""
	Remove all existing exercise rows from the scroll container.
	"""
	for child in scroll_content.get_children():
		child.queue_free()
	# Wait for the next frame to ensure children are actually removed
	await get_tree().process_frame

func _load_all_exercises():
	"""
	Load all exercises from ExerciseManager and create exercise rows for each.
	"""
	if not exercise_manager:
		push_error("ExerciseManager not available!")
		return
	
	# Reset filters to default
	current_filters["target_muscle"] = ""
	current_filters["bodyweight"] = ""
	
	# Load and display all exercises
	_apply_filters()

func _on_add_exercise_pressed():
	"""
	Create a new empty exercise row for adding a new exercise.
	"""
	if not exercise_row_scene:
		return
	
	var exercise_row = exercise_row_scene.instantiate()
	exercise_row.input_elements_container = input_container
	scroll_content.add_child(exercise_row)
	
	# Wait for the row to be ready, then focus the name input
	await get_tree().process_frame  # Wait one frame for _ready() to execute
	exercise_row.focus_target_input()
