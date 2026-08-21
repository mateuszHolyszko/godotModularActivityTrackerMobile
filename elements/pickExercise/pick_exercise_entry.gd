class_name PickExerciseEntry
extends OptionEntryMenu

signal exercise_selected(exercise_name)

var _exercise_manager: ExerciseManager
var _stage := "muscle"
var _selected_target := ""


func set_picker_data(exercise_manager: ExerciseManager, prompt: String = "") -> void:
	_exercise_manager = exercise_manager
	_prompt_text = prompt if not prompt.is_empty() else "Select target muscle"


func _ready() -> void:
	super._ready()
	option_selected.connect(_on_option_selected)


func _on_open() -> void:
	_stage = "muscle"
	_selected_target = ""
	set_options_data(MuscleDict.get_all_muscles(), null, _prompt_text)
	super._on_open()


func _on_option_selected(value) -> void:
	if _stage == "muscle":
		if value == null:
			request_close()
			return

		_selected_target = str(value)
		_stage = "exercise"
		var exercise_options: Array = []
		if _exercise_manager:
			for item in _exercise_manager.get_exercises_for_target(_selected_target):
				var exercise: Exercise = item.get("exercise")
				if exercise:
					exercise_options.append({"label": exercise.name, "value": exercise.name})

		set_options_data(exercise_options, null, "Select exercise for %s" % _selected_target)
		super._on_open()
		return

	if value == null:
		exercise_selected.emit(null)
	else:
		exercise_selected.emit(value)


func _on_cancel_pressed() -> void:
	if _stage == "exercise":
		_stage = "muscle"
		_selected_target = ""
		set_options_data(MuscleDict.get_all_muscles(), null, _prompt_text)
		super._on_open()
		return

	request_close()
