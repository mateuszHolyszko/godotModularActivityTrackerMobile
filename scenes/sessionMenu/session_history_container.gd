class_name SessionHistoryContainer
extends VBoxContainer

@onready var session_history_vb_template: VBoxContainer = %SessionHistoryVB_template

func _ready():
	_update_session_history()

# Call this to refresh the history list (e.g. after a workout finishes/aborts)
func refresh() -> void:
	_update_session_history()

func _update_session_history() -> void:
	# Clear existing history items (keep the template hidden)
	for child in get_children():
		if child != session_history_vb_template:
			child.queue_free()
	
	# Get recent sessions
	var recent_sessions = DataManager.SessionManager.get_recent_sessions(8)
	
	if recent_sessions.is_empty():
		# Show "No sessions" message
		var empty_label = Label.new()
		empty_label.text = "No sessions yet"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		add_child(empty_label)
		return
	
	# Create a VBoxContainer for each session
	for item in recent_sessions:
		var session: Session = item.get("session")
		if not session:
			continue
		
		# Duplicate the template
		var new_item = session_history_vb_template.duplicate()
		new_item.visible = true
		
		# Find the child labels by their names (assuming they have unique names)
		var session_name_label = new_item.get_node("SessionNameLabel") as Label
		var session_date_label = new_item.get_node("SessionDateLabel") as Label
		
		# Format the text: Program name on top, relative date on bottom
		var program_name = session.program.program_name if session.program else "Unknown Program"
		var relative_date = _get_relative_date(session.date)
		
		if session_name_label:
			session_name_label.text = program_name
		
		if session_date_label:
			session_date_label.text = relative_date
		
		add_child(new_item)

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
