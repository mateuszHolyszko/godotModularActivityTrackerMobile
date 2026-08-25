class_name SessionHistoryContainer
extends VBoxContainer

@onready var session_history_label_template: Label = %SessionHistoryLabel_tamplate

func _ready():
	_update_session_history()

# Call this to refresh the history list (e.g. after a workout finishes/aborts)
func refresh() -> void:
	_update_session_history()

func _update_session_history() -> void:
	# Clear existing history items (keep the template hidden)
	for child in get_children():
		if child != session_history_label_template:
			child.queue_free()
	
	# Get recent sessions
	var recent_sessions = DataManager.SessionManager.get_recent_sessions(10)
	
	if recent_sessions.is_empty():
		# Show "No sessions" message
		var empty_label = Label.new()
		empty_label.text = "No sessions yet"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		add_child(empty_label)
		return
	
	# Create a label for each session
	for item in recent_sessions:
		var session: Session = item.get("session")
		if not session:
			continue
		
		# Duplicate the template
		var new_label = session_history_label_template.duplicate()
		new_label.visible = true
		
		# Format the text: Program name on top, relative date on bottom
		var program_name = session.program.program_name if session.program else "Unknown Program"
		var relative_date = _get_relative_date(session.date)
		
		new_label.text = "%s\n%s" % [program_name, relative_date]
		
		add_child(new_label)



func _calculate_days_difference(year1: int, month1: int, day1: int, year2: int, month2: int, day2: int) -> int:
	# Calculate total days for each date (approximate)
	var days_in_month := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	
	# Function to calculate total days from year 0
	var total_days1 = year1 * 365 + day1
	var total_days2 = year2 * 365 + day2
	
	# Add months (simplified - using 31 days per month)
	for i in range(month1 - 1):
		total_days1 += 31  # Simplified
	for i in range(month2 - 1):
		total_days2 += 31  # Simplified
	
	return total_days2 - total_days1

# Alternative: More accurate day calculation using Time
func _get_days_between(year1: int, month1: int, day1: int, year2: int, month2: int, day2: int) -> int:
	# Convert both dates to Unix timestamps
	var datetime1 = {"year": year1, "month": month1, "day": day1, "hour": 0, "minute": 0, "second": 0}
	var datetime2 = {"year": year2, "month": month2, "day": day2, "hour": 0, "minute": 0, "second": 0}
	
	var timestamp1 = Time.get_unix_time_from_datetime_dict(datetime1)
	var timestamp2 = Time.get_unix_time_from_datetime_dict(datetime2)
	
	var diff_seconds = abs(timestamp2 - timestamp1)
	var diff_days = floor(diff_seconds / 86400)  # 86400 seconds in a day
	
	return diff_days

# Use this more accurate version instead of _calculate_days_difference
func _get_relative_date(date_str: String) -> String:
	# If no date, return default
	if date_str == "":
		return "No date"
	
	# Parse the date string (assuming format: YYYY-MM-DD)
	var date_parts = date_str.split("-")
	if date_parts.size() != 3:
		return date_str
	
	var year = int(date_parts[0])
	var month = int(date_parts[1])
	var day = int(date_parts[2])
	
	# Get current date
	var current_date = Time.get_date_dict_from_system()
	
	# Calculate days difference using Unix timestamps
	var session_datetime = {"year": year, "month": month, "day": day, "hour": 0, "minute": 0, "second": 0}
	var current_datetime = {"year": current_date.year, "month": current_date.month, "day": current_date.day, "hour": 0, "minute": 0, "second": 0}
	
	var session_timestamp = Time.get_unix_time_from_datetime_dict(session_datetime)
	var current_timestamp = Time.get_unix_time_from_datetime_dict(current_datetime)
	
	var diff_seconds = current_timestamp - session_timestamp
	var days_diff = floor(diff_seconds / 86400)  # 86400 seconds in a day
	
	# Handle future dates
	if days_diff < 0:
		return "in the future"
	
	# Handle today
	if days_diff == 0:
		return "today"
	
	# Determine the appropriate time unit
	var days_in_month := 31  # Simplified assumption
	
	if days_diff < 7:
		return "%d day%s ago" % [days_diff, "s" if days_diff != 1 else ""]
	elif days_diff < 31:
		var weeks = floor(days_diff / 7)
		return "%d week%s ago" % [weeks, "s" if weeks != 1 else ""]
	elif days_diff < 365:
		var months = floor(days_diff / days_in_month)
		return "%d month%s ago" % [months, "s" if months != 1 else ""]
	else:
		var years = floor(days_diff / 365)
		return "%d year%s ago" % [years, "s" if years != 1 else ""]
