class_name InputMeasurementsMenu
extends Menu

@onready var back_button: Button = %BackButton
@onready var save_button: Button = %SaveButton

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

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	save_button.pressed.connect(_on_save_pressed)
	
	# Load the last measurements
	_update_last_measurement_labels()
	_fill_inputs_with_last_values()
	
	# Color the input buttons
	_color_input_buttons()

func _color_input_buttons() -> void:
	# Color each input button with its corresponding measurement color
	_set_button_color(input_arms, "arms")
	_set_button_color(input_chest, "chest")
	_set_button_color(input_waist, "waist")
	_set_button_color(input_thigh, "thigh")
	#_set_button_color(input_weight, "weight")

func _on_back_pressed() -> void:
	request_close()

func _on_save_pressed() -> void:
	# Get the last measurements to compare against
	var last_measurements := DataManager.MeasurementManager.get_last_measurements()
	
	# Create a new measurement with current values
	var measurement := Measurement.new()
	
	# Get current timestamp
	measurement.timestamp = Time.get_unix_time_from_system()
	
	# Get values from inputs
	measurement.arms = input_arms.current_value
	measurement.chest = input_chest.current_value
	measurement.waist = input_waist.current_value
	measurement.thigh = input_thigh.current_value
	measurement.weight = input_weight.current_value
	
	# Check if any value has changed from the last measurement
	var has_changed := false
	
	if last_measurements.is_empty():
		# If no measurements exist, save everything
		has_changed = true
	else:
		# Check each measurement type
		if last_measurements.has("arms") and abs(measurement.arms - last_measurements["arms"].value) > 0.001:
			has_changed = true
		elif last_measurements.has("chest") and abs(measurement.chest - last_measurements["chest"].value) > 0.001:
			has_changed = true
		elif last_measurements.has("waist") and abs(measurement.waist - last_measurements["waist"].value) > 0.001:
			has_changed = true
		elif last_measurements.has("thigh") and abs(measurement.thigh - last_measurements["thigh"].value) > 0.001:
			has_changed = true
		elif last_measurements.has("weight") and abs(measurement.weight - last_measurements["weight"].value) > 0.001:
			has_changed = true
	
	# Only save if something changed
	if has_changed:
		# Save the measurement
		DataManager.MeasurementManager.add(measurement)
		
		# Update the labels with the new values
		_update_last_measurement_labels()
		
		print("Measurement saved successfully!")
	else:
		print("No changes detected. Measurement not saved.")

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
		last_arms_label.text = "%.1f cm" % arms_data.value
		last_arms_date_label.text = arms_data.date
	
	# Update chest
	if last_measurements.has("chest"):
		var chest_data = last_measurements["chest"]
		last_chest_label.text = "%.1f cm" % chest_data.value
		last_chest_date_label.text = chest_data.date
	
	# Update waist
	if last_measurements.has("waist"):
		var waist_data = last_measurements["waist"]
		last_waist_label.text = "%.1f cm" % waist_data.value
		last_waist_date_label.text = waist_data.date
	
	# Update thigh
	if last_measurements.has("thigh"):
		var thigh_data = last_measurements["thigh"]
		last_thigh_label.text = "%.1f cm" % thigh_data.value
		last_thigh_date_label.text = thigh_data.date
	
	# Update weight
	if last_measurements.has("weight"):
		var weight_data = last_measurements["weight"]
		last_weight_label.text = "%.1f kg" % weight_data.value
		last_weight_date_label.text = weight_data.date

# Optional: Add a function to pre-fill inputs with last values
func _fill_inputs_with_last_values() -> void:
	var last_measurements := DataManager.MeasurementManager.get_last_measurements()
	
	if last_measurements.is_empty():
		return
	
	# Only fill if the input is empty or zero
	if last_measurements.has("arms") and input_arms.current_value == 0.0:
		input_arms.current_value = last_measurements["arms"].value
	
	if last_measurements.has("chest") and input_chest.current_value == 0.0:
		input_chest.current_value = last_measurements["chest"].value
	
	if last_measurements.has("waist") and input_waist.current_value == 0.0:
		input_waist.current_value = last_measurements["waist"].value
	
	if last_measurements.has("thigh") and input_thigh.current_value == 0.0:
		input_thigh.current_value = last_measurements["thigh"].value
	
	if last_measurements.has("weight") and input_weight.current_value == 0.0:
		input_weight.current_value = last_measurements["weight"].value


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
