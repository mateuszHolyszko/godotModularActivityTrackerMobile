extends Panel

@onready var parent_menu: Menu = $"../../../../.."
@onready var pie_chart: PieChart = $PieChart

var _is_ready: bool = false

func _ready():
	_is_ready = true
	
	if not parent_menu:
		push_error("PieChartPanel: parent_menu not found")
		return
	
	# Connect to the parent menu's signals
	if parent_menu.has_signal("program_changed"):
		parent_menu.program_changed.connect(_on_program_changed)
	
	# Connect to the working_program_modified signal for real-time updates
	if parent_menu.has_signal("working_program_modified"):
		parent_menu.working_program_modified.connect(_on_working_program_modified)
	
	# Initial update
	_update_pie_chart()

func _on_program_changed(new_program: Program) -> void:
	"""
	Handle when the program changes in the parent menu.
	"""
	_update_pie_chart()

func _on_working_program_modified() -> void:
	"""
	Handle when the working program is modified.
	This provides real-time updates to the pie chart.
	"""
	_update_pie_chart()

func _update_pie_chart() -> void:
	"""
	Update the pie chart with the current program's target breakdown.
	"""
	if not _is_ready:
		return
	
	if not parent_menu:
		return
	
	# Get the working program from the parent menu
	var program: Program = null
	if parent_menu.has_method("get_working_program"):
		program = parent_menu.get_working_program()
	elif parent_menu.has_method("get_program_resource"):
		program = parent_menu.get_program_resource()
	
	if not program:
		# No program loaded, show empty chart
		pie_chart.set_data([])
		return
	
	# Get the target breakdown for the program
	var breakdown = DataManager.ProgramManager.get_program_target_breakdown(program)
	
	if breakdown.is_empty():
		# No exercises in program
		pie_chart.set_data([])
		return
	
	# Build the chart data array with colors
	var chart_data: Array[Dictionary] = []
	for muscle in breakdown:
		var count = breakdown[muscle]
		var color = MuscleDict.get_color(muscle)
		chart_data.append({
			"label": muscle,
			"value": count,
			"color": color
		})
	
	# Update the pie chart with the new data
	pie_chart.set_data(chart_data)

# Called when the panel is hidden or shown
func _visibility_changed() -> void:
	# If becoming visible, refresh the chart
	if visible:
		_update_pie_chart()

# Public method to manually refresh the pie chart
func refresh() -> void:
	"""
	Manually refresh the pie chart.
	Call this if the program data changes outside of the normal flow.
	"""
	_update_pie_chart()

# Public method to check if the pie chart has data
func has_data() -> bool:
	"""
	Check if the pie chart currently has any data to display.
	"""
	return pie_chart.get_element_count() > 0
