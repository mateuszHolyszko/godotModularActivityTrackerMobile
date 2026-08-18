extends MarginContainer

@onready var plotter: Plotter2D = $Plotter2D
@onready var query_week_input: NumericInputButton = %InputWeeks
@onready var query_measurement_input: OptionInputButton = %InputMeasurement

func _ready() -> void:
	# Connect value changed signals
	query_week_input.value_changed.connect(_on_query_parameters_changed)
	query_measurement_input.value_changed.connect(_on_query_parameters_changed)
	
	# Set default values
	query_week_input.current_value = 4  # Default to 4 weeks
	query_measurement_input.current_value = "weight"  # Default to weight
	
	# Initial query
	_on_query_parameters_changed()

func _on_query_parameters_changed(_new_value = null) -> void:
	# Get current values from inputs
	var weeks: int = int(query_week_input.current_value)
	var measurement_type: String = str(query_measurement_input.current_value)
	
	# Validate inputs
	if weeks <= 0:
		print("Please enter a valid number of weeks (greater than 0)")
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
