extends Menu

@onready var add_exercise_button: Button = %AddExerciseButton
@onready var scroll_content: VBoxContainer = %ScrollContent
@onready var input_container: Container = %SubMenuInputContainer

@onready var input_filter_target: OptionInputButton = %InputOptionTarget
@onready var input_filter_bodyweight: OptionInputButton = %InputOptionBodyweight
@onready var input_filter_modality: OptionInputButton = %InputOptionModalityFilter

@onready var _confirm_dialog: ConfirmationEntryMenu = %ConfirmationEntryMenu

var exercise_manager: ExerciseManager
var exercise_row_scene: PackedScene = null

var current_filters: Dictionary = {
	"target_muscle": "",
	"bodyweight": "",
	"modality": ""
}

# Guards against stale background results overwriting a newer request.
var _filter_request_id: int = 0


func _ready():
	exercise_manager = DataManager.ExerciseManager

	exercise_row_scene = load("res://scenes/exercisesMenu/exerciseRow/exerciseRow.tscn")

	add_exercise_button.pressed.connect(_on_add_exercise_pressed)

	if input_filter_target:
		input_filter_target.value_changed.connect(_on_filter_changed)
	if input_filter_bodyweight:
		input_filter_bodyweight.value_changed.connect(_on_filter_changed)
	if input_filter_modality:
		input_filter_modality.value_changed.connect(_on_filter_changed)

	_load_all_exercises()


func _create_exercise_row(exercise: Exercise, file_name: String = ""):
	"""
	Create an exercise row and populate it with the exercise data.
	MAIN THREAD ONLY - touches the scene tree.
	"""
	if not exercise_row_scene:
		return

	var exercise_row = exercise_row_scene.instantiate()
	exercise_row.input_elements_container = input_container
	exercise_row.set_exercise(exercise, file_name)
	exercise_row.confirm_dialog = _confirm_dialog

	scroll_content.add_child(exercise_row)


func _on_filter_changed(_value):
	"""
	Called when any filter changes. Updates the displayed exercises.
	"""
	current_filters["target_muscle"] = input_filter_target.current_value if input_filter_target else ""
	current_filters["bodyweight"] = input_filter_bodyweight.current_value if input_filter_bodyweight else ""
	current_filters["modality"] = input_filter_modality.current_value if input_filter_modality else ""

	_apply_filters()


func _apply_filters():
	"""
	Kick off a background task to compute the filtered exercise list.
	Does NOT touch the scene tree except to clear existing rows.
	"""
	#Before threading show loading screen to prevent inputs
	GlobalElements.LoadingScreen.show_loading()
	
	if not exercise_manager:
		push_error("ExerciseManager not available!")
		return

	_clear_exercise_rows()

	# Snapshot filter values now (main thread) so the worker doesn't read
	# UI state directly - keeps the worker function pure/thread-safe.
	# normalize the filter values, null breaks filters
	var target_muscle: String = _as_filter_string(current_filters.get("target_muscle", ""))
	var bodyweight_filter: String = _as_filter_string(current_filters.get("bodyweight", ""))
	var modality_filter: String = _as_filter_string(current_filters.get("modality", ""))

	_filter_request_id += 1
	var this_request_id = _filter_request_id

	WorkerThreadPool.add_task(
		_fetch_filtered_exercises.bind(target_muscle, bodyweight_filter, modality_filter, this_request_id)
	)


func _as_filter_string(value) -> String:
	return "" if value == null else str(value)

func _fetch_filtered_exercises(target_muscle: String, bodyweight_filter: String, modality_filter: String, request_id: int):
	"""
	WORKER THREAD. Pure data lookup/filtering - no node access, no tree access.
	Hands the result back to the main thread via call_deferred.
	"""
	
	var has_target_filter = target_muscle != null and target_muscle != "" and target_muscle != "None" and target_muscle != "All"
	var has_bodyweight_filter = bodyweight_filter != null and bodyweight_filter != "" and bodyweight_filter != "All"
	var has_modality_filter = modality_filter != null and modality_filter != "" and modality_filter != "All"

	var filtered_items = []

	if has_target_filter:
		var target_items = exercise_manager.get_exercises_for_target(target_muscle)
		#print("get_exercises_for_target returned")
		for item in target_items:
			filtered_items.append(item)
	else:
		var all_items = exercise_manager.get_exercises()
		for item in all_items:
			filtered_items.append(item)

	if has_bodyweight_filter:
		var is_bodyweight = bodyweight_filter == "Yes"
		var temp_items = []
		for item in filtered_items:
			var exercise = item.get("exercise")
			if exercise and exercise.bodyweight == is_bodyweight:
				temp_items.append(item)
		filtered_items = temp_items

	if has_modality_filter:
		var modality_exercises = exercise_manager.get_exercises_for_modality(modality_filter)

		var modality_exercise_names = {}
		for ex in modality_exercises:
			modality_exercise_names[ex.name] = true

		var temp_items = []
		for item in filtered_items:
			var exercise = item.get("exercise")
			if exercise and modality_exercise_names.has(exercise.name):
				temp_items.append(item)
		filtered_items = temp_items

	var exercises_to_display = []
	for item in filtered_items:
		var exercise = item.get("exercise")
		var file_name = item.get("file_name", "")
		if exercise:
			exercises_to_display.append({"exercise": exercise, "file_name": file_name})

	print("fetch about to call_deferred")
	call_deferred("_on_filter_data_ready", exercises_to_display, request_id, target_muscle, bodyweight_filter, modality_filter)

# Since in most cases node cration takes the most time (30 ex -> 167ms) limit how many rows we create per frame so it doesnt visibly stutter
const ROWS_PER_FRAME := 1

func _on_filter_data_ready(exercises_to_display: Array, request_id: int, target_muscle: String, bodyweight_filter: String, modality_filter: String):
	"""
	MAIN THREAD (deferred call from the worker). Safe to touch the scene tree here.
	"""
	GlobalElements.LoadingScreen.hide_loading()
	
	# A newer filter request has since been made - discard this stale result.
	if request_id != _filter_request_id:
		return

	var made := 0
	for exercise_data in exercises_to_display:
		if request_id != _filter_request_id:
			return   # a newer request superseded us mid-build
		_create_exercise_row(exercise_data["exercise"], exercise_data["file_name"])
		made += 1
		if made % ROWS_PER_FRAME == 0:
			await get_tree().process_frame


func _clear_exercise_rows():
	"""
	Remove all existing exercise rows from the scroll container.
	MAIN THREAD ONLY.
	"""
	for child in scroll_content.get_children():
		child.queue_free()
	await get_tree().process_frame


func _load_all_exercises():
	"""
	Load all exercises from ExerciseManager and create exercise rows for each.
	"""
	if not exercise_manager:
		push_error("ExerciseManager not available!")
		return

	current_filters["target_muscle"] = ""
	current_filters["bodyweight"] = ""
	current_filters["modality"] = ""

	_apply_filters()


func _on_add_exercise_pressed():
	"""
	Create a new empty exercise row for adding a new exercise.
	"""
	if not exercise_row_scene:
		return

	var target_filter = input_filter_target.current_value if input_filter_target else ""
	var bodyweight_filter = input_filter_bodyweight.current_value if input_filter_bodyweight else ""
	var modality_filter = input_filter_modality.current_value if input_filter_modality else ""

	var has_target_filter = target_filter != null and target_filter != "" and target_filter != "None" and target_filter != "All"
	var has_bodyweight_filter = bodyweight_filter != null and bodyweight_filter != "" and bodyweight_filter != "All"
	var has_modality_filter = modality_filter != null and modality_filter != "" and modality_filter != "All"

	if has_target_filter or has_bodyweight_filter or has_modality_filter:
		input_filter_target.current_value = "All"
		input_filter_bodyweight.current_value = "All"
		input_filter_modality.current_value = "All"
		_on_filter_changed(null)
		NotificationManager.info("Filters cleared for adding exercise")

	for child in scroll_content.get_children():
		if child.has_method("is_empty") and child.is_empty():
			await get_tree().process_frame
			child.focus_target_input()
			NotificationManager.info("Focusing existing empty exercise")
			return

	var exercise_row = exercise_row_scene.instantiate()
	exercise_row.input_elements_container = input_container
	exercise_row.confirm_dialog = _confirm_dialog
	scroll_content.add_child(exercise_row)

	NotificationManager.info("Appended Empty Exercise")

	await get_tree().process_frame
	exercise_row.focus_target_input()
