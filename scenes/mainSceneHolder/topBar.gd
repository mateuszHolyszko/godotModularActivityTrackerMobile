extends Node

@onready var timeLabel: Label = %TimeLabel
@onready var dateLabel: Label = %DateLabel
@onready var dateTimeTimer: Timer = %DateTimeTimer

@onready var session_status_label: Label = %SessionStatusLabel

# Timer for status updates
var status_update_timer: Timer = null

func _ready():
	update_datetime()
	dateTimeTimer.timeout.connect(update_datetime)
	
	# Create timer for status updates 
	status_update_timer = Timer.new()
	status_update_timer.wait_time = 0.5
	status_update_timer.timeout.connect(_update_session_status)
	add_child(status_update_timer)
	status_update_timer.start()
	
	# Initial update
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

func _update_session_status() -> void:
	var current_workout = GlobalElements.CurrentWorkout
	
	if current_workout and current_workout.is_active():
		session_status_label.text = "Active Session"
		session_status_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		session_status_label.text = "No Active Session"
		session_status_label.remove_theme_color_override("font_color")

func _exit_tree() -> void:
	if status_update_timer:
		status_update_timer.stop()
		status_update_timer.queue_free()
