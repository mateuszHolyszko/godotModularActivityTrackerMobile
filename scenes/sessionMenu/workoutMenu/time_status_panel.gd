extends Panel
@onready var signal_bus: WorkoutMenuSignalBus = %WorkoutMenuSignalBus

@onready var started_time_label: Label = %StartedTimeLabel # format "Started: hh:mm"
@onready var elapsed_time_label: Label = %ElapsedTimeLabel # format "Elapsed: hh:mm"
@onready var average_time_label: Label = %AverageTimeLabel #  
@onready var rest_time_label: Label = %RestTimeLabel # format "Rest time: --:--"

# Reference to the current workout session
var current_workout: WorkoutSession = null

# Timer for updating elapsed time
var update_timer: Timer = null

# Timestamp (unix seconds) of the last completed set, 0 = none yet
var _last_set_edited_timestamp: int = 0

func _ready() -> void:
	# Set up timer for elapsed time updates
	update_timer = Timer.new()
	update_timer.wait_time = 1.0
	update_timer.timeout.connect(_update_elapsed_time)
	add_child(update_timer)
	
	# Connect to GlobalElements signals
	if GlobalElements.CurrentWorkout.has_signal("workout_started"):
		GlobalElements.CurrentWorkout.workout_started.connect(_on_workout_started)
	if GlobalElements.CurrentWorkout.has_signal("workout_completed"):
		GlobalElements.CurrentWorkout.workout_completed.connect(_on_workout_ended)
	if GlobalElements.CurrentWorkout.has_signal("workout_cancelled"):
		GlobalElements.CurrentWorkout.workout_cancelled.connect(_on_workout_ended)
	
	# Connect to the session menu signal bus for set completions
	if signal_bus:
		signal_bus.set_edited.connect(_on_set_edited)
	
	# Check if there's already an active workout
	if GlobalElements.CurrentWorkout and GlobalElements.CurrentWorkout.is_active():
		_on_workout_started()
	
	# Initial update for average time
	_update_average_time()

func _on_workout_started() -> void:
	current_workout = GlobalElements.CurrentWorkout
	_last_set_edited_timestamp = 0
	_update_started_time()
	_update_elapsed_time()
	_update_rest_time()
	update_timer.start()

func _on_workout_ended() -> void:
	update_timer.stop()
	_update_elapsed_time() # Final update
	_update_rest_time()
	current_workout = null
	# Update average time after workout ends (may have new session data)
	_update_average_time()

func _on_set_edited(_exercise_index: int, _set_index: int) -> void:
	"""Reset the rest timer whenever a set is completed"""
	_last_set_edited_timestamp = Time.get_unix_time_from_system()
	_update_rest_time()

func _update_started_time() -> void:
	if not current_workout or current_workout.start_timestamp == 0:
		started_time_label.text = "Started: --:--"
		return
	
	# Get UTC datetime
	var utc_datetime = Time.get_datetime_dict_from_unix_time(current_workout.start_timestamp)
	
	# Get timezone offset in seconds
	var timezone_offset = Time.get_time_zone_from_system().bias * 60  # bias is in minutes
	
	# Apply offset
	var local_timestamp = current_workout.start_timestamp + timezone_offset
	var local_datetime = Time.get_datetime_dict_from_unix_time(local_timestamp)
	
	started_time_label.text = "Started: %02d:%02d" % [local_datetime.hour, local_datetime.minute]

func _update_elapsed_time() -> void:
	if not current_workout:
		elapsed_time_label.text = "Elapsed: --:--"
		return
	
	if current_workout.is_active():
		elapsed_time_label.text = "Elapsed: " + current_workout.get_elapsed_time_string()
	else:
		# Workout completed - show final duration
		var minutes = current_workout.get_duration_minutes()
		var seconds = current_workout.get_duration_seconds() % 60
		elapsed_time_label.text = "Elapsed: %02d:%02d" % [minutes, seconds]
	
	# Elapsed timer also drives the rest-time display so they stay in sync
	_update_rest_time()

func _update_rest_time() -> void:
	"""Show time since the last completed set, or --:-- if none yet"""
	if _last_set_edited_timestamp == 0:
		rest_time_label.text = "Rest Time: --:--"
		return
	
	var now := int(Time.get_unix_time_from_system())
	var rest_seconds := now - _last_set_edited_timestamp
	if rest_seconds < 0:
		rest_seconds = 0
	
	var minutes := rest_seconds / 60
	var seconds := rest_seconds % 60
	rest_time_label.text = "Rest Time: %02d:%02d" % [minutes, seconds]

func _update_average_time() -> void:
	# Get current program from workout if active, otherwise use last program
	var program_name = ""
	
	if current_workout and current_workout.program:
		program_name = current_workout.program.program_name
	elif current_workout and current_workout.program_name:
		program_name = current_workout.program_name
	
	print("PROGRAM in time: ", program_name)
	# If we have a program name, calculate average
	if program_name != "":
		var avg_time = DataManager.SessionManager.get_avg_session_time(program_name)
		if avg_time > 0:
			var minutes = floor(avg_time)
			var seconds = round((avg_time - minutes) * 60)
			average_time_label.text = "Avg: %02d:%02d" % [minutes, seconds]
		else:
			average_time_label.text = "Avg: --:--"
	else:
		average_time_label.text = "Avg: --:--"

# Public methods for manual updates (if needed)
func refresh() -> void:
	if current_workout:
		_update_started_time()
		_update_elapsed_time()
	_update_average_time()

func get_workout_session() -> WorkoutSession:
	return current_workout

func is_workout_active() -> bool:
	return current_workout != null and current_workout.is_active()
