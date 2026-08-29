extends MarginContainer

@onready var plotter: Plotter2D = $Plotter2D
@onready var query_date_input: DateInputButton = %InputDate
@onready var query_measurement_input: OptionInputButton = %InputMeasurement


func _ready() -> void:
	# Connect value changed signals
	query_date_input.date_changed.connect(_on_query_parameters_changed)
	query_measurement_input.value_changed.connect(_on_query_parameters_changed)

	# Set default values
	query_date_input.current_duration = {"day": 28, "month": 0, "year": 0}  # Default to ~4 weeks
	query_measurement_input.current_value = "weight"  # Default to weight

	# Initial query
	_on_query_parameters_changed()


func _on_query_parameters_changed(_new_value = null) -> void:
	# Get current values from inputs
	var weeks: int = _duration_to_weeks(query_date_input.current_duration)
	var measurement_type: String = str(query_measurement_input.current_value)

	# Validate inputs
	if weeks <= 0:
		print("Please enter a valid lookback period (greater than 0 days)")
		return

	if measurement_type.is_empty():
		print("Please select a measurement type")
		return

	# Clear existing plots
	plotter.clear()

	# Always plot weight
	_plot_measurement("weight", weeks)

	# Plot the selected measurement if it's not weight
	if measurement_type != "weight":
		_plot_measurement(measurement_type, weeks)


## Converts the picked duration (day/month/year, months treated as 31 days,
## per DataInputButton's convention) into a week count for the existing
## week-based query API.
func _duration_to_weeks(duration: Dictionary) -> int:
	var total_days: int = duration.year * 365 + duration.month * 31 + duration.day
	return int(ceil(total_days / 7.0))


func _plot_measurement(measurement_type: String, weeks: int) -> void:
	# Query the measurement data
	var records = DataManager.MeasurementManager.query_measurement_by_weeks(measurement_type, weeks)

	# Check if we have data
	if records.is_empty():
		print("No %s measurements found in the last %d week(s)" % [measurement_type, weeks])
		return

	# Prepare data for plotting
	var timestamps: PackedFloat32Array = PackedFloat32Array()
	var values: PackedFloat32Array = PackedFloat32Array()

	for record in records:
		timestamps.append(float(record.timestamp))
		values.append(record.value)

	# Get color from the MEASUREMENTS_COLORS dictionary
	var color: Color = MuscleDict.MEASUREMENTS_COLORS.get(measurement_type, Color.WHITE)

	# Add the plot line
	plotter.add_plot_line(
		timestamps,
		values,
		color,
		measurement_type.capitalize()
	)

	print("Plotted %s measurements for the last %d weeks" % [measurement_type, weeks])
