extends Control


@export var input_elements_container: Container
@export var exercise_resource: Exercise = null

@export var confirm_dialog: ConfirmationEntryMenu


@onready var input_target: OptionInputButton = %TargetOptionButton
@onready var input_ex_name: TextInputButton = %InputExerciseName
@onready var input_bodyweight: OptionInputButton = %InputOptionBodyweight
@onready var input_rep_range_bot: NumericInputButton = %InputNumericBotRange
@onready var input_rep_range_top: NumericInputButton = %InputNumericTopRange
@onready var save_button: Button = %ButtonSave
@onready var delete_button: Button = %ButtonDelete

@onready var input_modality: OptionInputButton = %InputOptionModality
@onready var modifier_pick_button: ModifierPickButton = %ModifierPickButton

@onready var edit_indicator_panel: Panel = %EditIndicatorPanel # make visible when there are changes to be saved


var exercise_manager: ExerciseManager
var current_file_name: String = ""  # Track the filename for updating

var _pending_exercise: Exercise = null  # Store exercise until _ready
var _pending_file_name: String = ""    # Store filename until _ready


func _ready():
	exercise_manager = DataManager.ExerciseManager

	_assign_container_to_inputs()
	_connect_signals()

	# Hide edit indicator initially.
	edit_indicator_panel.visible = false

	# If there's a pending exercise from set_exercise() called before _ready
	if _pending_exercise:
		exercise_resource = _pending_exercise
		current_file_name = _pending_file_name
		_populate_fields_from_resource()
		_pending_exercise = null
		_pending_file_name = ""

	# If exercise_resource is provided (via export), populate the fields
	if exercise_resource and not _pending_exercise:
		_populate_fields_from_resource()

	# Apply initial styling if there's a default value
	_apply_styling_to_inputs()

	# Hide delete button if no exercise_resource (new exercise)
	if not exercise_resource:
		delete_button.visible = false


func _assign_container_to_inputs():
	var container_path = input_elements_container.get_path()

	for element in [
		input_target,
		input_ex_name,
		input_bodyweight,
		input_rep_range_bot,
		input_rep_range_top,
		input_modality,
		modifier_pick_button
	]:
		element.submenu_container_path = container_path


func _connect_signals():
	# Any input change should check for unsaved changes.
	input_target.value_changed.connect(_on_input_changed)
	input_ex_name.value_changed.connect(_on_input_changed)
	input_bodyweight.value_changed.connect(_on_input_changed)
	input_rep_range_bot.value_changed.connect(_on_input_changed)
	input_rep_range_top.value_changed.connect(_on_input_changed)
	input_modality.value_changed.connect(_on_input_changed)
	modifier_pick_button.value_changed.connect(_on_input_changed)

	# Target selection also updates styling.
	input_target.value_changed.connect(_on_target_changed)

	# Connect the save button
	if save_button:
		save_button.pressed.connect(_on_save_pressed)

	# Connect the delete button
	if delete_button:
		delete_button.pressed.connect(_on_delete_pressed)


# ================================================================
# UNSAVED CHANGES
# ================================================================

func _on_input_changed(_value = null) -> void:
	_update_edit_indicator()


func _update_edit_indicator() -> void:
	# There is nothing to compare against for a new exercise.
	if not exercise_resource:
		edit_indicator_panel.visible = false
		return

	edit_indicator_panel.visible = _has_unsaved_changes()


func _has_unsaved_changes() -> bool:
	# ------------------------------------------------------------
	# Name
	# ------------------------------------------------------------

	if input_ex_name.current_value != exercise_resource.name:
		return true


	# ------------------------------------------------------------
	# Target muscle
	# ------------------------------------------------------------

	if input_target.current_value != exercise_resource.target_muscle:
		return true


	# ------------------------------------------------------------
	# Bodyweight
	# ------------------------------------------------------------

	var bodyweight_value = input_bodyweight.current_value

	var current_bodyweight = (
		bodyweight_value != null
		and (
			bodyweight_value == "Yes"
			or str(bodyweight_value).to_lower() == "true"
		)
	)

	if current_bodyweight != exercise_resource.bodyweight:
		return true


	# ------------------------------------------------------------
	# Rep range
	# ------------------------------------------------------------

	if input_rep_range_bot.current_value != exercise_resource.rep_range.x:
		return true

	if input_rep_range_top.current_value != exercise_resource.rep_range.y:
		return true


	# ------------------------------------------------------------
	# Modality
	# ------------------------------------------------------------

	var current_modality: String = (
		input_modality.current_value
		if input_modality.current_value != null
		else ""
	)

	current_modality = current_modality.strip_edges()

	if current_modality != exercise_resource.modality:
		return true


	var current_modifiers: Array[String] = modifier_pick_button.get_modifiers()
	var resource_modifiers: Array[String] = exercise_resource.modifiers.duplicate()
	current_modifiers.sort()
	resource_modifiers.sort()

	if current_modifiers != resource_modifiers:
		return true


	# Everything matches the original resource.
	return false


# ================================================================
# TARGET STYLING
# ================================================================

func _on_target_changed(value):
	_apply_styling_to_inputs()


func _apply_styling_to_inputs():
	var selected_target = input_target.current_value

	if not selected_target or selected_target.is_empty():
		return

	# Apply styling to both input_target and input_ex_name
	_apply_style_to_element(input_target, selected_target)
	_apply_style_to_element(input_ex_name, selected_target)


func _apply_style_to_element(element: Control, muscle_name: String):
	"""
	Apply styling to a single element based on the muscle name.
	"""

	var color = MuscleDict.MUSCLE_COLORS.get(muscle_name)

	if not color:
		return

	# Set font color to black for all states
	element.add_theme_color_override("font_color", Color.BLACK)
	element.add_theme_color_override("font_hover_color", Color.BLACK)
	element.add_theme_color_override("font_pressed_color", Color.BLACK)
	element.add_theme_color_override("font_disabled_color", Color.BLACK)
	element.add_theme_color_override("font_focus_color", Color.BLACK)

	# Normal state
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color
	element.add_theme_stylebox_override("normal", normal_style)

	# Hover state
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = color
	hover_style.border_width_left = 8
	hover_style.border_color = Color.WHITE
	hover_style.border_width_bottom = 3
	hover_style.border_width_top = 3
	hover_style.border_width_right = 3
	element.add_theme_stylebox_override("hover", hover_style)

	# Pressed state
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = color
	pressed_style.border_width_left = 8
	pressed_style.border_color = Color.WHITE
	pressed_style.border_width_bottom = 8
	pressed_style.border_width_top = 8
	pressed_style.border_width_right = 8
	element.add_theme_stylebox_override("pressed", pressed_style)


# ================================================================
# FOOT PLACEMENT CONVERSION
# ================================================================

# Every modifier option's displayed text equals its stored value,
# EXCEPT foot placement, where the display swaps '_' for ' '.
#
# Example:
# stored:   "feet_narrow"
# displayed: "feet narrow"

func _foot_placement_display_to_value(display_value: String) -> String:
	if display_value == null or display_value.strip_edges().is_empty():
		return ""

	return display_value.replace(" ", "_")


func _foot_placement_value_to_display(value: String) -> String:
	if value == null or value.strip_edges().is_empty():
		return ""

	return value.replace("_", " ")


# ================================================================
# POPULATE INPUTS
# ================================================================

func _populate_fields_from_resource():
	"""
	Populate all input fields from the exercise_resource.
	"""

	if not exercise_resource:
		return

	# Check if nodes are ready
	if not input_ex_name:
		push_error("input_ex_name is not ready yet!")
		return

	input_ex_name.current_value = exercise_resource.name
	input_target.current_value = exercise_resource.target_muscle

	# Convert bool to string for the option button
	input_bodyweight.current_value = (
		"Yes" if exercise_resource.bodyweight else "No"
	)

	input_rep_range_bot.current_value = exercise_resource.rep_range.x
	input_rep_range_top.current_value = exercise_resource.rep_range.y

	# Modality: option text == stored value directly,
	# "" means unset/none
	input_modality.current_value = exercise_resource.modality

	modifier_pick_button.set_modifiers(exercise_resource.modifiers)

	# Show delete button since we have an existing exercise
	delete_button.visible = true

	# Apply styling after populating
	_apply_styling_to_inputs()

	# These values now exactly represent the resource,
	# so there are no unsaved changes.
	edit_indicator_panel.visible = false


# ================================================================
# COLLECT INPUT DATA
# ================================================================

func _collect_input_data() -> Dictionary:
	"""
	Collect and validate all input data.
	Returns a dictionary with the data if valid,
	or an error message if invalid.
	"""

	var name = input_ex_name.current_value
	var target = input_target.current_value
	var bodyweight_string = input_bodyweight.current_value
	var rep_min = input_rep_range_bot.current_value
	var rep_max = input_rep_range_top.current_value

	# Convert bodyweight string to bool
	var bodyweight = (
		bodyweight_string == "Yes"
		or bodyweight_string.to_lower() == "true"
	)

	# Validate inputs
	if name.strip_edges().is_empty():
		return {
			"valid": false,
			"error": "Exercise name cannot be empty"
		}

	if target.strip_edges().is_empty():
		return {
			"valid": false,
			"error": "Target muscle cannot be empty"
		}

	if not target in MuscleDict.MUSCLE_COLORS.keys():
		return {
			"valid": false,
			"error": "Invalid target muscle selected"
		}

	if rep_min < 0 or rep_max < 0:
		return {
			"valid": false,
			"error": "Rep range values must be non-negative"
		}

	if rep_min > rep_max:
		return {
			"valid": false,
			"error": "Min reps cannot be greater than max reps"
		}

	# ------------------------------------------------------------
	# Modality
	# ------------------------------------------------------------

	var modality: String = (
		input_modality.current_value
		if input_modality.current_value != null
		else ""
	)

	modality = modality.strip_edges()

	if modality != "" and not modality in Exercise.MODALITIES:
		return {
			"valid": false,
			"error": "Invalid modality selected"
		}

	var modifiers: Array[String] = modifier_pick_button.get_modifiers()
	var seen_categories: Dictionary = {}

	for modifier in modifiers:
		var category = Exercise.get_modifier_category(modifier)
		if category.is_empty() or seen_categories.has(category):
			return {
				"valid": false,
				"error": "Invalid modifiers selected"
			}
		seen_categories[category] = true


	return {
		"valid": true,
		"name": name.strip_edges(),
		"target": target.strip_edges(),
		"bodyweight": bodyweight,
		"rep_min": rep_min,
		"rep_max": rep_max,
		"modality": modality,
		"modifiers": modifiers,
	}


# ================================================================
# SAVE
# ================================================================

func _on_save_pressed():
	"""
	Handle save button press - validates and saves the exercise.
	"""

	if not exercise_manager:
		push_error("ExerciseManager not available!")
		NotificationManager.error("Exercise manager not available")
		return

	var data = _collect_input_data()

	if not data.valid:
		push_error("Validation failed: %s" % data.error)
		NotificationManager.error(data.error)
		return

	# ------------------------------------------------------------
	# Existing exercise
	# ------------------------------------------------------------

	if exercise_resource:

		# Update the existing exercise
		exercise_resource.name = data.name
		exercise_resource.target_muscle = data.target
		exercise_resource.bodyweight = data.bodyweight
		exercise_resource.rep_range = Vector2i(
			data.rep_min,
			data.rep_max
		)
		exercise_resource.modality = data.modality
		exercise_resource.modifiers = data.modifiers

		# Note:
		# secondary_targets has no dedicated input in this row yet,
		# so it's left as-is.

		# Save the updated exercise
		var new_file_name = exercise_manager.save_exercise_file(
			exercise_resource
		)

		if new_file_name != "":
			# If the filename changed,
			# remove the old one.
			if (
				current_file_name != ""
				and current_file_name != new_file_name
			):
				var old_path = (
					exercise_manager.exercises_directory
					+ current_file_name
				)

				if FileAccess.file_exists(old_path):
					var dir := DirAccess.open(
						exercise_manager.exercises_directory
					)

					if dir:
						dir.remove(current_file_name)

			current_file_name = new_file_name

			# Resource now represents the saved state,
			# so hide the indicator.
			edit_indicator_panel.visible = false

			print(
				"Exercise updated and saved: %s"
				% exercise_resource.name
			)

			NotificationManager.success(
				"Exercise '%s' updated"
				% exercise_resource.name
			)

	# ------------------------------------------------------------
	# New exercise
	# ------------------------------------------------------------

	else:

		var exercise = Exercise.new()

		exercise.name = data.name
		exercise.target_muscle = data.target
		exercise.bodyweight = data.bodyweight
		exercise.rep_range = Vector2i(
			data.rep_min,
			data.rep_max
		)
		exercise.modality = data.modality
		exercise.modifiers = data.modifiers

		# Add to manager (this saves the file)
		exercise_manager.add(exercise)

		# Store the resource and filename for future updates
		exercise_resource = exercise

		current_file_name = (
			exercise_manager.get_exercises()[-1]
			.get("file_name", "")
		)

		# Show delete button now that we have an exercise
		delete_button.visible = true

		# There are no unsaved changes after creation.
		edit_indicator_panel.visible = false

		print(
			"New exercise created and saved: %s"
			% exercise.name
		)

		NotificationManager.success(
			"Exercise '%s' created"
			% exercise.name
		)


# ================================================================
# DELETE
# ================================================================

func _on_delete_pressed():
	"""
	Handle delete button press - asks for confirmation before deleting.
	"""

	if not exercise_manager:
		push_error("ExerciseManager not available!")
		NotificationManager.error("Exercise manager not available")
		return

	if not exercise_resource:
		push_error("Cannot delete: no exercise resource loaded!")
		NotificationManager.error("Cannot delete: no exercise loaded")
		return

	# Check if confirm_dialog is available
	if not confirm_dialog:
		push_error("Confirm dialog not set for exercise row")
		NotificationManager.error("Confirmation dialog not available")
		return

	# Request confirmation before deleting
	var exercise_name := exercise_resource.name
	var confirm_message := "Delete exercise '%s'?" % exercise_name

	confirm_dialog.request_confirmation(
		confirm_message,
		_on_delete_confirmed
	)


func _on_delete_confirmed() -> void:
	"""
	Handle the confirmed deletion of the exercise.
	"""

	if not exercise_manager:
		push_error("ExerciseManager not available!")
		return

	if not exercise_resource:
		push_error("Cannot delete: no exercise resource loaded!")
		return

	# Delete the exercise from the manager
	var deleted = exercise_manager.remove_exercise(
		exercise_resource.name
	)

	# TODO delete history attached to this exercise?

	if deleted:
		print(
			"Exercise deleted: %s"
			% exercise_resource.name
		)

		NotificationManager.success(
			"Exercise '%s' deleted"
			% exercise_resource.name
		)

		queue_free()

	else:
		push_error(
			"Failed to delete exercise: %s"
			% exercise_resource.name
		)

		NotificationManager.error(
			"Failed to delete exercise '%s'"
			% exercise_resource.name
		)


func _on_delete_cancelled() -> void:
	print(
		"Delete cancelled for exercise: ",
		exercise_resource.name
	)


# ================================================================
# SET EXERCISE
# ================================================================

func set_exercise(
	exercise: Exercise,
	file_name: String = ""
):
	"""
	Public method to set the exercise resource and populate fields.
	Use this when loading an existing exercise.
	"""

	# If _ready hasn't run yet,
	# store the exercise for later.
	if not is_node_ready():
		_pending_exercise = exercise
		_pending_file_name = file_name
		return

	exercise_resource = exercise
	current_file_name = file_name

	_populate_fields_from_resource()


# ================================================================
# CLEAR FIELDS
# ================================================================

func clear_fields():
	"""
	Clear all input fields and reset the exercise resource.
	"""

	exercise_resource = null
	current_file_name = ""

	input_ex_name.clear()
	input_target.clear()
	input_bodyweight.clear()
	input_rep_range_bot.clear()
	input_rep_range_top.clear()
	input_modality.clear()
	modifier_pick_button.set_modifiers([])

	delete_button.visible = false

	# No resource to compare against.
	edit_indicator_panel.visible = false


# ================================================================
# MUSCLE STYLING
# ================================================================

# Keep the original apply_muscle_style
# for backward compatibility if needed.
func apply_muscle_style():
	"""
	Apply styling based on the muscle group color
	to all relevant elements.
	"""

	_apply_styling_to_inputs()


# ================================================================
# FOCUS
# ================================================================

# Focus for add exercise button in data_menu,
# so we can call it when its child elements are ready.
func focus_target_input():
	"""
	Focus the exercise name input field.
	"""

	if input_target:
		input_target.grab_focus()
		return true

	return false


# ================================================================
# EMPTY CHECK
# ================================================================

func is_empty() -> bool:
	"""
	Check if this is an empty exercise row
	(no exercise resource).
	"""

	return exercise_resource == null
