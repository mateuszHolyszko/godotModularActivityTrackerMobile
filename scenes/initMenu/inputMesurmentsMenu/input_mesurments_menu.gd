class_name InputMeasurementsMenu
extends Menu

const MEASUREMENT_TYPES := ["arms", "chest", "waist", "thigh", "weight"]
const CHANGE_THRESHOLD := 0.01

@onready var back_button: Button = %BackButton
@onready var save_button: Button = %SaveButton
@onready var confirm_dialog: ConfirmationEntryMenu = %ConfirmationEntryMenu

@onready var plotter_container: MarginContainer = %PlotterContainer

@onready var last_weight_label: Label = %LabelPreviousValueWeight
@onready var last_weight_date_label: Label = %LabelDateWeight
@onready var input_weight: NumericInputButton = %InputWeight

@onready var last_arms_label: Label = %LabelPreviousValueArms
@onready var last_arms_date_label: Label = %LabelDateArms
@onready var input_arms: NumericInputButton = %InputArms

@onready var last_chest_label: Label = %LabelPreviousValueChest
@onready var last_chest_date_label: Label = %LabelDateChest
@onready var input_chest: NumericInputButton = %InputChest

@onready var last_waist_label: Label = %LabelPreviousValueWaist
@onready var last_waist_date_label: Label = %LabelDateWaist
@onready var input_waist: NumericInputButton = %InputWaist

@onready var last_thigh_label: Label = %LabelPreviousValueThigh
@onready var last_thigh_date_label: Label = %LabelDateThigh
@onready var input_thigh: NumericInputButton = %InputThigh

var _has_unsaved_changes: bool = false

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	save_button.pressed.connect(_on_save_pressed)
	
	# Load the last measurements
	_update_last_measurement_labels()
	_fill_inputs_with_last_values()
	
	# Color the input buttons
	_color_input_buttons()
	
	# Track edits on each input so the Save button reflects unsaved state.
	# NOTE: assumes NumericInputButton emits `value_changed`; rename if different.
	for measurement_type in MEASUREMENT_TYPES:
		var input := _input_for_type(measurement_type)
		if input and input.has_signal("value_changed"):
			input.value_changed.connect(_on_input_value_changed)
	
	_update_save_button_state()

func _on_input_value_changed(_value: float = 0.0) -> void:
	_mark_unsaved_changes()

func _mark_unsaved_changes() -> void:
	"""
	Mark that there are unsaved changes and update the Save button styling.
	"""
	_has_unsaved_changes = true
	_update_save_button_state()

func _update_save_button_state() -> void:
	"""
	Update the save button appearance based on unsaved changes.
	"""
	if _has_unsaved_changes:
		save_button.text = "Save Changes *"
		save_button.modulate = Color(1, 1, 0)  # Yellow tint
	else:
		save_button.text = "Save Changes"
		save_button.modulate = Color(1, 1, 1)  # Reset color

func _color_input_buttons() -> void:
	# Color each input button with its corresponding measurement color
	_set_button_color(input_arms, "arms")
	_set_button_color(input_chest, "chest")
	_set_button_color(input_waist, "waist")
	_set_button_color(input_thigh, "thigh")
	#_set_button_color(input_weight, "weight")

func _on_back_pressed() -> void:
	# Check for unsaved changes before closing
	if _has_unsaved_changes:
		confirm_dialog.request_confirmation(
			"You have unsaved changes. Are you sure you want to leave?",
			_on_back_confirmed
		)
	else:
		_on_back_confirmed()

func _on_back_confirmed() -> void:
	#request_close() # this removes key, use close() instead
	#close()
	MenuManager.switch_to("init")

# Maps a measurement type to the NumericInputButton that holds its current value.
func _input_for_type(measurement_type: String) -> NumericInputButton:
	match measurement_type:
		"arms":
			return input_arms
		"chest":
			return input_chest
		"waist":
			return input_waist
		"thigh":
			return input_thigh
		"weight":
			return input_weight
		_:
			return null

func _on_save_pressed() -> void:
	# Get the last measurements to compare against, one lookup covers all types.
	var last_measurements := DataManager.MeasurementManager.get_last_measurements()
	
	var timestamp := Time.get_unix_time_from_system()
	var saved_types: Array[String] = []
	
	# Each measurement type is saved independently. Inputs are pre-filled with
	# the last recorded value, so "unchanged" (not "empty") is what tells us
	# to skip a type — otherwise every save would re-write all five.
	for measurement_type in MEASUREMENT_TYPES:
		var input := _input_for_type(measurement_type)
		if not input:
			continue
		
		var value: float = input.current_value
		var should_save: bool
		
		if last_measurements.has(measurement_type):
			var last_value: float = last_measurements[measurement_type].value
			# Same as last time (within float tolerance) -> skip.
			should_save = abs(value - last_value) >= CHANGE_THRESHOLD
		else:
			# No prior entry for this type, so nothing pre-filled it. A value
			# still sitting at 0.0 means the field was left untouched.
			should_save = value != 0.0
		
		if should_save:
			DataManager.MeasurementManager.add_entry(measurement_type, value, timestamp)
			saved_types.append(measurement_type)
			# Update weight label in parent menu
			_parent_menu._update_weight_label()
	
	if not saved_types.is_empty():
		# Update the labels with the new values
		_update_last_measurement_labels()
		
		# Refresh the plotter so the new data point(s) show up immediately
		if plotter_container.has_method("_on_query_parameters_changed"):
			plotter_container._on_query_parameters_changed()
		
		print("Measurement(s) saved: %s" % ", ".join(saved_types))
		NotificationManager.success("Measurement saved")
	else:
		print("No changes detected. Nothing saved.")
		NotificationManager.info("No changes detected — nothing to save")
	
	# Reset unsaved changes flag and styling after a save attempt
	_has_unsaved_changes = false
	_update_save_button_state()

func _update_last_measurement_labels() -> void:
	# Get the last measurements for all types
	var last_measurements := DataManager.MeasurementManager.get_last_measurements()
	
	# Check if we have any measurements
	if last_measurements.is_empty():
		# Set default labels when no measurements exist
		last_arms_label.text = "No data"
		last_arms_date_label.text = ""
		last_chest_label.text = "No data"
		last_chest_date_label.text = ""
		last_waist_label.text = "No data"
		last_waist_date_label.text = ""
		last_thigh_label.text = "No data"
		last_thigh_date_label.text = ""
		last_weight_label.text = "No data"
		last_weight_date_label.text = ""
		return
	
	# Update arms
	if last_measurements.has("arms"):
		var arms_data = last_measurements["arms"]
		last_arms_label.text = "%.2f cm" % arms_data.value
		last_arms_date_label.text = _format_date(arms_data.date)
	else:
		last_arms_label.text = "No data"
		last_arms_date_label.text = ""
	
	# Update chest
	if last_measurements.has("chest"):
		var chest_data = last_measurements["chest"]
		last_chest_label.text = "%.2f cm" % chest_data.value
		last_chest_date_label.text = _format_date(chest_data.date)
	else:
		last_chest_label.text = "No data"
		last_chest_date_label.text = ""
	
	# Update waist
	if last_measurements.has("waist"):
		var waist_data = last_measurements["waist"]
		last_waist_label.text = "%.2f cm" % waist_data.value
		last_waist_date_label.text = _format_date(waist_data.date)
	else:
		last_waist_label.text = "No data"
		last_waist_date_label.text = ""
	
	# Update thigh
	if last_measurements.has("thigh"):
		var thigh_data = last_measurements["thigh"]
		last_thigh_label.text = "%.2f cm" % thigh_data.value
		last_thigh_date_label.text = _format_date(thigh_data.date)
	else:
		last_thigh_label.text = "No data"
		last_thigh_date_label.text = ""
	
	# Update weight
	if last_measurements.has("weight"):
		var weight_data = last_measurements["weight"]
		last_weight_label.text = "%.2f kg" % weight_data.value
		last_weight_date_label.text = _format_date(weight_data.date)
	else:
		last_weight_label.text = "No data"
		last_weight_date_label.text = ""

# Converts a date string from "yyyy-mm-dd" (optionally with a time part,
# e.g. "yyyy-mm-dd hh:mm:ss") to "dd-mm-yyyy". If the string doesn't match
# the expected pattern, it's returned unchanged.
func _format_date(date_string: String) -> String:
	if date_string.is_empty():
		return date_string
	
	# Only look at the date portion, in case a time component is included
	var date_part := date_string.split(" ")[0]
	var parts := date_part.split("-")
	
	if parts.size() != 3:
		return date_string
	
	var year := parts[0]
	var month := parts[1]
	var day := parts[2]
	
	return "%s-%s-%s" % [day, month, year]

# Pre-fill inputs with each type's last recorded value, independently.
func _fill_inputs_with_last_values() -> void:
	var last_measurements := DataManager.MeasurementManager.get_last_measurements()
	
	if last_measurements.is_empty():
		return
	
	for measurement_type in MEASUREMENT_TYPES:
		if not last_measurements.has(measurement_type):
			continue
		
		var input := _input_for_type(measurement_type)
		if input and input.current_value == 0.0:
			input.current_value = last_measurements[measurement_type].value

func _set_button_color(button: Button, measurement_type: String) -> void:
	# Get the color from the measurements colors dictionary
	var color: Color = MuscleDict.MEASUREMENTS_COLORS.get(measurement_type, Color.WHITE)
	
	# Set alpha to 200 (0-255 range, so 200/255 ≈ 0.78)
	color.a = 200.0 / 255.0
	
	# Create a new stylebox and copy existing properties if available
	var existing_stylebox := button.get_theme_stylebox("normal")
	var stylebox: StyleBoxFlat
	
	if existing_stylebox is StyleBoxFlat:
		# If it's already a StyleBoxFlat, duplicate it
		stylebox = existing_stylebox.duplicate()
	else:
		# Otherwise create a new one with default settings
		stylebox = StyleBoxFlat.new()
		stylebox.corner_radius_top_left = 4
		stylebox.corner_radius_top_right = 4
		stylebox.corner_radius_bottom_left = 4
		stylebox.corner_radius_bottom_right = 4
	
	# Only change the background color
	stylebox.bg_color = color
	
	# Apply the modified stylebox
	button.add_theme_stylebox_override("normal", stylebox)
	button.add_theme_stylebox_override("hover", stylebox)
	button.add_theme_stylebox_override("pressed", stylebox)
