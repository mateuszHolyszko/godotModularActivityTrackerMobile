extends Panel

@onready var started_time_label: Label = %StartedTimeLabel # format "Started: hh:mm"
@onready var elapsed_time_label: Label = %ElapsedTimeLabel # format "Elapsed: hh:mm"
@onready var average_time_label: Label = %AverageTimeLabel # DONT IMPLEMENT YET

# Reference to the current workout session
var current_workout: WorkoutSession = null

# Timer for updating elapsed time
var update_timer: Timer = null

func _ready() -> void:
	# Set up timer for elapsed time updates
	update_timer = Timer.new()
	update_timer.wait_time = 1.0
	update_timer.timeout.connect(_update_elapsed_time)
	add_child(update_timer)
	
	# Connect to GlobalElements signals
	if GlobalElements.has_signal("workout_started"):
		GlobalElements.workout_started.connect(_on_workout_started)
	if GlobalElements.has_signal("workout_completed"):
		GlobalElements.workout_completed.connect(_on_workout_ended)
	if GlobalElements.has_signal("workout_cancelled"):
		GlobalElements.workout_cancelled.connect(_on_workout_ended)
	
	# Check if there's already an active workout
	if GlobalElements.CurrentWorkout and GlobalElements.CurrentWorkout.is_active():
		_on_workout_started()
	

func _on_workout_started() -> void:
	current_workout = GlobalElements.CurrentWorkout
	_update_started_time()
	_update_elapsed_time()
	update_timer.start()

func _on_workout_ended() -> void:
	update_timer.stop()
	_update_elapsed_time() # Final update
	current_workout = null

func _update_started_time() -> void:
	if not current_workout or current_workout.start_timestamp == 0:
		started_time_label.text = "Started: --:--"
		return
	
	var datetime = Time.get_datetime_dict_from_unix_time(current_workout.start_timestamp)
	started_time_label.text = "Started: %02d:%02d" % [datetime.hour, datetime.minute]

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


# Public methods for manual updates (if needed)
func refresh() -> void:
	if current_workout:
		_update_started_time()
		_update_elapsed_time()

func get_workout_session() -> WorkoutSession:
	return current_workout

func is_workout_active() -> bool:
	return current_workout != null and current_workout.is_active()

# Clean up when node is removed
func _exit_tree() -> void:
	if update_timer:
		update_timer.stop()
		update_timer.queue_free()
