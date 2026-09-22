extends Panel

@onready var root_exercise_row: Control = $".."

@onready var expand_button: PopupPanelButton = %ExpandExerciseHistoryButton
@onready var exercise_history_plotter: Plotter2D = %ExerciseHistoryPlotter

# Query time buttons
@onready var one_month_toggle: Button = %OneMonthButton
@onready var three_months_toggle: Button = %ThreeMonthsButton
@onready var one_year_toggle: Button = %OneYearButton

var chosen_query_time = DataManager.ExerciseEntryManager.QueryTime.ONE_MONTH


func _ready() -> void:
	expand_button.expanded.connect(_on_expand_button_expanded)

	one_month_toggle.toggled.connect(_on_one_month_toggled)
	three_months_toggle.toggled.connect(_on_three_months_toggled)
	one_year_toggle.toggled.connect(_on_one_year_toggled)

	# Ensure the default is reflected in the UI
	one_month_toggle.button_pressed = true


# ---------------------------------------------------------
# Query time toggles
# ---------------------------------------------------------

func _on_one_month_toggled(pressed: bool) -> void:
	if not pressed:
		return
	chosen_query_time = DataManager.ExerciseEntryManager.QueryTime.ONE_MONTH
	_untoggle_except(one_month_toggle)
	_refresh_plot()


func _on_three_months_toggled(pressed: bool) -> void:
	if not pressed:
		return
	chosen_query_time = DataManager.ExerciseEntryManager.QueryTime.THREE_MONTHS
	_untoggle_except(three_months_toggle)
	_refresh_plot()


func _on_one_year_toggled(pressed: bool) -> void:
	if not pressed:
		return
	chosen_query_time = DataManager.ExerciseEntryManager.QueryTime.ONE_YEAR
	_untoggle_except(one_year_toggle)
	_refresh_plot()


func _untoggle_except(active: Button) -> void:
	if active != one_month_toggle:
		one_month_toggle.button_pressed = false
	if active != three_months_toggle:
		three_months_toggle.button_pressed = false
	if active != one_year_toggle:
		one_year_toggle.button_pressed = false


# ---------------------------------------------------------
# Expansion
# ---------------------------------------------------------

func _on_expand_button_expanded() -> void:
	_refresh_plot()


# ---------------------------------------------------------
# Plot refresh
# ---------------------------------------------------------

func _refresh_plot() -> void:
	# Only bother redrawing if the panel is currently expanded.
	if not expand_button.is_expanded:
		return

	exercise_history_plotter.clear()

	var exercise = root_exercise_row.exercise_data.exercise
	if exercise == null:
		return

	var first_set = DataManager.ExerciseEntryManager.get_sets_data_point_for_exercise(
		exercise.name,
		0,
		chosen_query_time
	)

	if not first_set["success"]:
		return

	exercise_history_plotter.add_plot_line(
		first_set["timestamps"],
		first_set["weight_values"],
		MuscleDict.get_color(exercise.target_muscle),
		"Weight"
	)

	exercise_history_plotter.add_plot_line(
		first_set["timestamps"],
		first_set["reps_values"],
		Color.WHITE,
		"Reps"
	)
