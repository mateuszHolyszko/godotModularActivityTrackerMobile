class_name VolumeSummaryPanel
extends Panel

@onready var bar_chart: BarChart = %BarChart
@onready var no_data_container: CenterContainer = $NoDataContainer

func _ready():
	_update_chart()

func _update_chart() -> void:
	# Get volume data for all muscles in the last 31 days
	var volume_dict = DataManager.SessionManager.get_volume_for_all_muscles_in_range(31)
	
	# Check if there's any data
	var has_data := false
	for value in volume_dict.values():
		if value > 0:
			has_data = true
			break
	
	# Show/hide appropriate containers
	if has_data:
		bar_chart.visible = true
		no_data_container.visible = false
		bar_chart.set_data(volume_dict)
	else:
		bar_chart.visible = false
		no_data_container.visible = true

# Call this to refresh with different time range
func refresh(days: int = 31) -> void:
	var volume_dict = DataManager.SessionManager.get_volume_for_all_muscles_in_range(days)
	
	# Check if there's any data
	var has_data := false
	for value in volume_dict.values():
		if value > 0:
			has_data = true
			break
	
	# Show/hide appropriate containers
	if has_data:
		bar_chart.visible = true
		no_data_container.visible = false
		bar_chart.set_data(volume_dict)
	else:
		bar_chart.visible = false
		no_data_container.visible = true
