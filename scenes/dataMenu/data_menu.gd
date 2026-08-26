extends Menu

@onready var add_exercise_button: Button = %AddExerciseButton
@onready var scroll_content: VBoxContainer = %ScrollContent
@onready var input_container: Container = %SubMenuInputContainer

@onready var loading_panel: LoadingPanel = %LoadingPanel

@onready var input_filter_target: OptionInputButton = %InputOptionTarget
@onready var input_filter_bodyweight: OptionInputButton = %InputOptionBodyweight

@onready var _confirm_dialog: ConfirmationEntryMenu = %ConfirmationEntryMenu

var exercise_manager: ExerciseManager
var exercise_row_scene: PackedScene = null

var current_filters: Dictionary = {
	"target_muscle": "",
	"bodyweight": ""
}

var _is_loading: bool = false
var _rows_per_frame: int = 8
var _filter_thread: Thread = null

func _ready():
	exercise_manager = DataManager.ExerciseManager
	exercise_row_scene = load("res://scenes/dataMenu/exerciseRow/exerciseRow.tscn")

	add_exercise_button.pressed.connect(_on_add_exercise_pressed)

	if input_filter_target:
		input_filter_target.value_changed.connect(_on_filter_changed)
	if input_filter_bodyweight:
		input_filter_bodyweight.value_changed.connect(_on_filter_changed)

	_load_all_exercises()


func _create_exercise_row(exercise: Exercise, file_name: String = ""):
	if not exercise_row_scene:
		return
	var exercise_row = exercise_row_scene.instantiate()
	exercise_row.input_elements_container = input_container
	exercise_row.set_exercise(exercise, file_name)
	exercise_row.confirm_dialog = _confirm_dialog
	scroll_content.add_child(exercise_row)

func _on_filter_changed(_value):
	current_filters["target_muscle"] = input_filter_target.current_value if input_filter_target else ""
	current_filters["bodyweight"] = input_filter_bodyweight.current_value if input_filter_bodyweight else ""
	_apply_filters()

func _apply_filters() -> void:
	if not exercise_manager:
		push_error("ExerciseManager not available!")
		return
	if _is_loading:
		return

	_is_loading = true
	if loading_panel:
		loading_panel.show_loading()

	await _clear_exercise_rows()
	await get_tree().process_frame  # let panel + clear actually paint

	# --- Threaded filtering ---
	# Snapshot filter values so the thread doesn't touch any Node state.
	var target_muscle: String = current_filters.get("target_muscle", "")
	var bodyweight_filter: String = current_filters.get("bodyweight", "")

	if _filter_thread and _filter_thread.is_alive():
		# Shouldn't happen due to _is_loading guard, but be safe.
		_filter_thread.wait_to_finish()

	_filter_thread = Thread.new()
	_filter_thread.start(_compute_filtered_list.bind(target_muscle, bodyweight_filter))

	# Poll without blocking the main thread
	while _filter_thread.is_alive():
		await get_tree().process_frame

	var exercises_to_display: Array = _filter_thread.wait_to_finish()

	# --- Batched row creation (must stay on main thread) ---
	var count := 0
	for exercise_data in exercises_to_display:
		_create_exercise_row(exercise_data["exercise"], exercise_data["file_name"])
		count += 1
		if count % _rows_per_frame == 0:
			await get_tree().process_frame

	print("Displayed %d exercise(s) with filters: target='%s', bodyweight='%s'" % [exercises_to_display.size(), target_muscle, bodyweight_filter])

	_is_loading = false
	if loading_panel:
		loading_panel.hide_loading()

# Runs on a background thread. MUST NOT touch scene tree, Nodes, or
# anything not passed in as plain data/resources here.
func _compute_filtered_list(target_muscle: String, bodyweight_filter: String) -> Array:
	#OS.delay_msec(500)  # 0.5 second delay to simiulate big data
	var has_target_filter = target_muscle != null and target_muscle != "" and target_muscle != "None" and target_muscle != "All"
	var has_bodyweight_filter = bodyweight_filter != null and bodyweight_filter != "" and bodyweight_filter != "All"

	var exercises_to_display: Array = []

	if has_target_filter and not has_bodyweight_filter:
		var filtered_items = exercise_manager.get_exercises_for_target(target_muscle)
		for item in filtered_items:
			var exercise = item.get("exercise")
			var file_name = item.get("file_name", "")
			if exercise:
				exercises_to_display.append({"exercise": exercise, "file_name": file_name})

	elif not has_target_filter and has_bodyweight_filter:
		var all_items = exercise_manager.get_exercises()
		var is_bodyweight = bodyweight_filter == "Yes"
		for item in all_items:
			var exercise = item.get("exercise")
			var file_name = item.get("file_name", "")
			if exercise and exercise.bodyweight == is_bodyweight:
				exercises_to_display.append({"exercise": exercise, "file_name": file_name})

	elif has_target_filter and has_bodyweight_filter:
		var filtered_items = exercise_manager.get_exercises_for_target(target_muscle)
		var is_bodyweight = bodyweight_filter == "Yes"
		for item in filtered_items:
			var exercise = item.get("exercise")
			var file_name = item.get("file_name", "")
			if exercise and exercise.bodyweight == is_bodyweight:
				exercises_to_display.append({"exercise": exercise, "file_name": file_name})
	else:
		var all_items = exercise_manager.get_exercises()
		for item in all_items:
			var exercise = item.get("exercise")
			var file_name = item.get("file_name", "")
			if exercise:
				exercises_to_display.append({"exercise": exercise, "file_name": file_name})

	return exercises_to_display

func _clear_exercise_rows() -> void:
	for child in scroll_content.get_children():
		child.queue_free()
	await get_tree().process_frame

func _load_all_exercises():
	if not exercise_manager:
		push_error("ExerciseManager not available!")
		return
	current_filters["target_muscle"] = ""
	current_filters["bodyweight"] = ""
	_apply_filters()

func _on_add_exercise_pressed():
	if not exercise_row_scene:
		return

	var target_filter = input_filter_target.current_value if input_filter_target else ""
	var bodyweight_filter = input_filter_bodyweight.current_value if input_filter_bodyweight else ""

	var has_target_filter = target_filter != null and target_filter != "" and target_filter != "None" and target_filter != "All"
	var has_bodyweight_filter = bodyweight_filter != null and bodyweight_filter != "" and bodyweight_filter != "All"

	if has_target_filter or has_bodyweight_filter:
		input_filter_target.current_value = "All"
		input_filter_bodyweight.current_value = "All"
		_on_filter_changed(null)
		NotificationManager.info("Filters cleared for adding exercise")
		while _is_loading:
			await get_tree().process_frame

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
