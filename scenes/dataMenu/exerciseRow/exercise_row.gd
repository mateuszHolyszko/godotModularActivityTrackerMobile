extends Control

@export var input_elements_container: Container
@export var exercise_resource: Exercise = null

@onready var input_target: OptionInputButton = %TargetOptionButton
@onready var input_ex_name: TextInputButton = %InputExerciseName
@onready var input_bodyweight: OptionInputButton = %InputOptionBodyweight
@onready var input_rep_range_bot: NumericInputButton = %InputNumericBotRange
@onready var input_rep_range_top: NumericInputButton = %InputNumericTopRange
@onready var save_button: Button = %ButtonSave
@onready var delete_button: Button = %ButtonDelete

var exercise_manager: ExerciseManager
var current_file_name: String = ""  # Track the filename for updating
var _pending_exercise: Exercise = null  # Store exercise until _ready
var _pending_file_name: String = ""    # Store filename until _ready

func _ready():
	exercise_manager = DataManager.ExerciseManager
	
	_assign_container_to_inputs()
	_connect_signals()
	
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
	
	for element in [input_target, input_ex_name, input_bodyweight, input_rep_range_bot, input_rep_range_top]:
		element.submenu_container_path = container_path

func _connect_signals():
	# Connect the target selection change to update styling
	input_target.value_changed.connect(_on_target_changed)
	
	# Connect the save button
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
	
	# Connect the delete button
	if delete_button:
		delete_button.pressed.connect(_on_delete_pressed)

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

func _populate_fields_from_resource():
	"""
	Populate all input fields from the exercise_resource.
	"""
	if not exercise_resource:
		return
	
	# Check if nodes are ready (they should be by now)
	if not input_ex_name:
		push_error("input_ex_name is not ready yet!")
		return
	
	input_ex_name.current_value = exercise_resource.name
	input_target.current_value = exercise_resource.target_muscle
	
	# Convert bool to string for the option button
	input_bodyweight.current_value = ("Yes" if exercise_resource.bodyweight else "No")
	
	input_rep_range_bot.current_value = exercise_resource.rep_range.x
	input_rep_range_top.current_value = exercise_resource.rep_range.y
	
	# Show delete button since we have an existing exercise
	delete_button.visible = true
	
	# Apply styling after populating
	_apply_styling_to_inputs()

func _collect_input_data() -> Dictionary:
	"""
	Collect and validate all input data.
	Returns a dictionary with the data if valid, or an error message if invalid.
	"""
	var name = input_ex_name.current_value
	var target = input_target.current_value
	var bodyweight_string = input_bodyweight.current_value
	var rep_min = input_rep_range_bot.current_value
	var rep_max = input_rep_range_top.current_value
	
	# Convert bodyweight string to bool
	var bodyweight = (bodyweight_string == "Yes" or bodyweight_string.to_lower() == "true")
	
	# Validate inputs
	if name.strip_edges().is_empty():
		return {"valid": false, "error": "Exercise name cannot be empty"}
	
	if target.strip_edges().is_empty():
		return {"valid": false, "error": "Target muscle cannot be empty"}
	
	if not target in MuscleDict.MUSCLE_COLORS.keys():
		return {"valid": false, "error": "Invalid target muscle selected"}
	
	if rep_min < 0 or rep_max < 0:
		return {"valid": false, "error": "Rep range values must be non-negative"}
	
	if rep_min > rep_max:
		return {"valid": false, "error": "Min reps cannot be greater than max reps"}
	
	return {
		"valid": true,
		"name": name.strip_edges(),
		"target": target.strip_edges(),
		"bodyweight": bodyweight,
		"rep_min": rep_min,
		"rep_max": rep_max
	}

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
	
	# If we have an existing exercise resource, update it
	if exercise_resource:
		# Update the existing exercise
		exercise_resource.name = data.name
		exercise_resource.target_muscle = data.target
		exercise_resource.bodyweight = data.bodyweight
		exercise_resource.rep_range = Vector2i(data.rep_min, data.rep_max)
		
		# Save the updated exercise (this will create a new file if needed)
		var new_file_name = exercise_manager.save_exercise_file(exercise_resource)
		if new_file_name != "":
			# If the filename changed, we need to remove the old one
			if current_file_name != "" and current_file_name != new_file_name:
				var old_path = exercise_manager.exercises_directory + current_file_name
				if FileAccess.file_exists(old_path):
					var dir := DirAccess.open(exercise_manager.exercises_directory)
					if dir:
						dir.remove(current_file_name)
			
			current_file_name = new_file_name
			print("Exercise updated and saved: %s" % exercise_resource.name)
			NotificationManager.success("Exercise '%s' updated" % exercise_resource.name)
	else:
		# Create a new exercise
		var exercise = Exercise.new()
		exercise.name = data.name
		exercise.target_muscle = data.target
		exercise.bodyweight = data.bodyweight
		exercise.rep_range = Vector2i(data.rep_min, data.rep_max)
		
		# Add to manager (this saves the file)
		exercise_manager.add(exercise)
		
		# Store the resource and filename for future updates
		exercise_resource = exercise
		current_file_name = exercise_manager.get_exercises()[-1].get("file_name", "")
		
		# Show delete button now that we have an exercise
		delete_button.visible = true
		
		print("New exercise created and saved: %s" % exercise.name)
		NotificationManager.success("Exercise '%s' created" % exercise.name)
	
	# Optionally emit a signal or show a success message
	# Signal to notify parent that data was saved
func _on_delete_pressed():
	"""
	Handle delete button press - deletes the exercise and removes this row.
	"""
	if not exercise_manager:
		push_error("ExerciseManager not available!")
		NotificationManager.error("Exercise manager not available")
		return
	
	if not exercise_resource:
		push_error("Cannot delete: no exercise resource loaded!")
		NotificationManager.error("Cannot delete: no exercise loaded")
		return
	
	# Ask for confirmation (optional but recommended)
	# You could show a confirmation dialog here
	
	# Delete the exercise from the manager
	var deleted = exercise_manager.remove_exercise(exercise_resource.name)
	
	# TODO delete history attatched to this exercise?
	
	if deleted:
		print("Exercise deleted: %s" % exercise_resource.name)
		NotificationManager.success("Exercise '%s' deleted" % exercise_resource.name)
		# Delete this row/scene
		queue_free()
	else:
		push_error("Failed to delete exercise: %s" % exercise_resource.name)
		NotificationManager.error("Failed to delete exercise '%s'" % exercise_resource.name)

func set_exercise(exercise: Exercise, file_name: String = ""):
	"""
	Public method to set the exercise resource and populate fields.
	Use this when loading an existing exercise.
	"""
	# If _ready hasn't run yet, store the exercise for later
	if not is_node_ready():
		_pending_exercise = exercise
		_pending_file_name = file_name
		return
	
	exercise_resource = exercise
	current_file_name = file_name
	_populate_fields_from_resource()

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
	delete_button.visible = false

# Keep the original apply_muscle_style for backward compatibility if needed
func apply_muscle_style():
	"""
	Apply styling based on the muscle group color to all relevant elements.
	"""
	_apply_styling_to_inputs()

# focus for add exrcise button in data_menu, so we can call it when its child elements are ready
func focus_target_input():
	"""
	Focus the exercise name input field.
	"""
	if input_target:
		input_target.grab_focus()
		return true
	return false

func is_empty() -> bool:
	"""Check if this is an empty exercise row (no exercise resource)."""
	return exercise_resource == null
