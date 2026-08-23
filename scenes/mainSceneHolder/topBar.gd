extends Node

@onready var timeLabel: Label = %TimeLabel
@onready var dateLabel: Label = %DateLabel
@onready var dateTimeTimer: Timer = %DateTimeTimer

@onready var session_status_label: Label = %SessionStatusLabel

func _ready():
	update_datetime()
	dateTimeTimer.timeout.connect(update_datetime)
	
	# Connect to GlobalElements signal
	GlobalElements.CurrentWorkoutChanged.connect(_on_current_workout_changed)
	
	# Initial update based on current state
	_update_session_status()

func update_datetime():
	var current_time = Time.get_datetime_dict_from_system()

	timeLabel.text = "%02d:%02d" % [
		current_time.hour,
		current_time.minute
	]

	dateLabel.text = "%02d-%02d\n%04d" % [
		current_time.day,
		current_time.month,
		current_time.year
	]

# === Workout Session Status ===

func _on_current_workout_changed(workout: WorkoutSession) -> void:
	# Disconnect from old workout signals if needed
	# (if you had connections to the workout itself)
	
	_update_session_status()

func _update_session_status() -> void:
	var current_workout = GlobalElements.CurrentWorkout
	
	if current_workout:
		session_status_label.text = "Active Session"
		session_status_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		session_status_label.text = "No Active Session"
		session_status_label.remove_theme_color_override("font_color")

# Clean up
func _exit_tree() -> void:
	if GlobalElements.is_connected("CurrentWorkoutChanged", _on_current_workout_changed):
		GlobalElements.CurrentWorkoutChanged.disconnect(_on_current_workout_changed)
