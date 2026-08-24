extends Node
class_name WorkoutSession

# Core workout data
var program: Program = null
var start_timestamp: int = 0  # Unix timestamp
var end_timestamp: int = 0    # Unix timestamp
var exercise_data: Array = []  # Array of WorkoutExerciseData

# Internal tracking
var _is_active: bool = false
var _elapsed_time: float = 0.0

# Signals
signal exercise_added(exercise_data_index: int)
signal exercise_removed(exercise_data_index: int)
signal exercise_updated(exercise_data_index: int)
signal set_added(exercise_data_index: int, set_index: int)
signal set_removed(exercise_data_index: int, set_index: int)
signal set_updated(exercise_data_index: int, set_index: int)
signal workout_started()
signal workout_completed(total_duration: int)
signal workout_cancelled()

# Sub-class for exercise data
class WorkoutExerciseData:
	var exercise: Exercise
	var note: String = ""
	var sets: Array = []  # Array of {order: int, weight: float, reps: int}
	
	func _init(p_exercise: Exercise):
		exercise = p_exercise
		note = p_exercise.note if p_exercise else ""
	
	func add_set(weight: float, reps: int) -> void:
		sets.append({
			"order": sets.size(),
			"weight": weight,
			"reps": reps
		})
	
	func remove_set_at(index: int) -> bool:
		if index < 0 or index >= sets.size():
			return false
		sets.remove_at(index)
		# Reorder
		for i in range(index, sets.size()):
			sets[i]["order"] = i
		return true
	
	func update_set(index: int, weight: float, reps: int) -> bool:
		if index < 0 or index >= sets.size():
			return false
		sets[index]["weight"] = weight
		sets[index]["reps"] = reps
		return true
	
	func get_total_volume() -> float:
		var total := 0.0
		for set_data in sets:
			total += set_data["weight"] * set_data["reps"]
		return total
	
	func get_max_weight() -> float:
		var max_weight := 0.0
		for set_data in sets:
			if set_data["weight"] > max_weight:
				max_weight = set_data["weight"]
		return max_weight
	
	func get_total_reps() -> int:
		var total := 0
		for set_data in sets:
			total += set_data["reps"]
		return total
	
	func to_dict() -> Dictionary:
		var serialized_sets: Array = []
		for set_data in sets:
			serialized_sets.append({
				"order": set_data["order"],
				"weight": set_data["weight"],
				"reps": set_data["reps"]
			})
		
		return {
			"exercise_name": exercise.name if exercise else "",
			"note": note,
			"sets": serialized_sets,
		}
	
	static func from_dict(d: Dictionary, exercise_manager) -> WorkoutExerciseData:
		var exercise_name = str(d.get("exercise_name", ""))
		var exercise = exercise_manager.get_exercise(exercise_name) if exercise_manager else null
		
		var data = WorkoutExerciseData.new(exercise)
		data.note = str(d.get("note", data.note))
		
		var raw_sets = d.get("sets", [])
		if typeof(raw_sets) == TYPE_ARRAY:
			for raw_set in raw_sets:
				if typeof(raw_set) == TYPE_DICTIONARY:
					data.sets.append({
						"order": int(raw_set.get("order", data.sets.size())),
						"weight": float(raw_set.get("weight", 0.0)),
						"reps": int(raw_set.get("reps", 0))
					})
		
		return data

# === Workout Management ===

func start_workout(p_program: Program) -> void:
	if _is_active:
		push_warning("WorkoutSession: Workout already in progress")
		return
	
	program = p_program
	start_timestamp = Time.get_unix_time_from_system()
	end_timestamp = 0
	_is_active = true
	exercise_data.clear()
	
	# Pre-populate with exercises from program
	if program:
		var resolved = program.resolve(DataManager.ExerciseManager)
		for item in resolved:
			if item.get("type") == "exercise":
				var exercise = item.get("exercise")
				if exercise:
					# Add the exercise to the workout
					var exercise_index = add_exercise(exercise)
					
					# Pre-populate sets with last found entries for this exercise
					_prepopulate_sets_from_history(exercise_index, exercise)
	
	workout_started.emit()
	print("WorkoutSession: Started workout with program '%s'" % (program.program_name if program else "Unknown"))

func _prepopulate_sets_from_history(exercise_index: int, exercise: Exercise) -> void:
	"""Pre-populate sets for an exercise using the last found entry"""
	if exercise_index < 0 or not exercise:
		return
	
	# Get the latest entry for this exercise
	var latest_entry = DataManager.ExerciseEntryManager.get_latest_entry_for_exercise(exercise.name)
	
	if not latest_entry:
		print("WorkoutSession: No history found for exercise '%s'" % exercise.name)
		return
	
	# Get the sets from the latest entry
	var latest_sets = latest_entry.sets
	
	if latest_sets.is_empty():
		print("WorkoutSession: No sets found in latest entry for exercise '%s'" % exercise.name)
		return
	
	# Add each set from the latest entry to the current workout
	for set_data in latest_sets:
		var weight = set_data.get("weight", 0.0)
		var reps = set_data.get("reps", 0)
		add_set_to_exercise(exercise_index, weight, reps)
	
	print("WorkoutSession: Pre-populated %d sets for exercise '%s' from history" % [latest_sets.size(), exercise.name])

func _get_latest_entry(entries: Array[ExerciseEntry]) -> ExerciseEntry:
	"""Get the most recent ExerciseEntry from an array of entries"""
	if entries.is_empty():
		return null
	
	# If entries are already sorted by session date, the first one might be the latest
	# But to be safe, we'll find the one with the most recent session
	
	var latest_entry = entries[0]
	var latest_session = DataManager.SessionManager.get_session_by_id(latest_entry.session_id)
	
	for entry in entries:
		var session = DataManager.SessionManager.get_session_by_id(entry.session_id)
		if session and latest_session:
			# Compare session dates
			if session.date > latest_session.date:
				latest_entry = entry
				latest_session = session
		elif session and not latest_session:
			# If latest has no session but current has one, use current
			latest_entry = entry
			latest_session = session
	
	return latest_entry

func end_workout() -> void:
	if not _is_active:
		push_warning("WorkoutSession: No active workout to end")
		return
	
	end_timestamp = Time.get_unix_time_from_system()
	_is_active = false
	var duration = get_duration_minutes()
	workout_completed.emit(duration)
	print("WorkoutSession: Completed workout - Duration: %d minutes" % duration)

func cancel_workout() -> void:
	if not _is_active:
		return
	
	_is_active = false
	exercise_data.clear()
	workout_cancelled.emit()
	print("WorkoutSession: Workout cancelled")

func is_active() -> bool:
	return _is_active

func get_duration_seconds() -> int:
	if start_timestamp == 0:
		return 0
	
	var end = end_timestamp if end_timestamp > 0 else Time.get_unix_time_from_system()
	return end - start_timestamp

func get_duration_minutes() -> int:
	return int(get_duration_seconds() / 60.0)

func get_elapsed_time_string() -> String:
	var seconds = get_duration_seconds()
	var minutes = seconds / 60
	var secs = seconds % 60
	return "%02d:%02d" % [minutes, secs]

# === Exercise Management ===

func add_exercise(exercise: Exercise) -> int:
	if not _is_active:
		push_error("WorkoutSession: Cannot add exercise to inactive workout")
		return -1
	
	var data = WorkoutExerciseData.new(exercise)
	exercise_data.append(data)
	var index = exercise_data.size() - 1
	exercise_added.emit(index)
	return index

func insert_exercise_at(index: int, exercise: Exercise) -> int:
	if not _is_active:
		push_error("WorkoutSession: Cannot insert exercise into inactive workout")
		return -1

	if not exercise or index < 0 or index > exercise_data.size():
		return -1

	var data = WorkoutExerciseData.new(exercise)
	exercise_data.insert(index, data)
	exercise_added.emit(index)
	_prepopulate_sets_from_history(index, exercise)
	return index

func add_exercise_by_name(exercise_name: String, exercise_manager) -> int:
	var exercise = exercise_manager.get_exercise(exercise_name)
	if not exercise:
		push_error("WorkoutSession: Exercise '%s' not found" % exercise_name)
		return -1
	return add_exercise(exercise)

func remove_exercise_at(index: int) -> bool:
	if not _is_active:
		push_error("WorkoutSession: Cannot remove exercise from inactive workout")
		return false
	
	if index < 0 or index >= exercise_data.size():
		return false
	
	exercise_data.remove_at(index)
	exercise_removed.emit(index)
	return true

func get_exercise_data_at(index: int) -> WorkoutExerciseData:
	if index < 0 or index >= exercise_data.size():
		return null
	return exercise_data[index]

func get_exercise_count() -> int:
	return exercise_data.size()

func get_total_volume() -> float:
	var total := 0.0
	for data in exercise_data:
		total += data.get_total_volume()
	return total

# === Set Management ===

func add_set_to_exercise(exercise_index: int, weight: float, reps: int) -> int:
	if not _is_active:
		push_error("WorkoutSession: Cannot add set to inactive workout")
		return -1
	
	var data = get_exercise_data_at(exercise_index)
	if not data:
		return -1
	
	data.add_set(weight, reps)
	var set_index = data.sets.size() - 1
	set_added.emit(exercise_index, set_index)
	return set_index

func remove_set_from_exercise(exercise_index: int, set_index: int) -> bool:
	if not _is_active:
		push_error("WorkoutSession: Cannot remove set from inactive workout")
		return false
	
	var data = get_exercise_data_at(exercise_index)
	if not data:
		return false
	
	var result = data.remove_set_at(set_index)
	if result:
		set_removed.emit(exercise_index, set_index)
	return result

func update_set(exercise_index: int, set_index: int, weight: float, reps: int) -> bool:
	if not _is_active:
		push_error("WorkoutSession: Cannot update set in inactive workout")
		return false
	
	var data = get_exercise_data_at(exercise_index)
	if not data:
		return false
	
	var result = data.update_set(set_index, weight, reps)
	if result:
		set_updated.emit(exercise_index, set_index)
	return result

func get_sets_for_exercise(exercise_index: int) -> Array:
	var data = get_exercise_data_at(exercise_index)
	if not data:
		return []
	return data.sets

# === Persistence ===

func save_to_session(exercise_manager, entry_manager, session_manager) -> Session:
	"""Convert the workout to a persistent Session and save it"""
	if _is_active:
		push_error("WorkoutSession: Cannot save active workout - end it first")
		return null
	
	if exercise_data.is_empty():
		push_error("WorkoutSession: Cannot save empty workout")
		return null
	
	#print("SAVED PROGRAM - ",program.program_name)
	# Create session
	var session = session_manager.create_session(
		program,
		Time.get_date_string_from_system(),
		get_duration_minutes()
	)
	
	# Create exercise entries
	for data in exercise_data:
		if data.exercise:
			exercise_manager.change_note(data.exercise, data.note)

		var entry = entry_manager.create_entry(
			data.exercise,
			session.session_id,
			data.sets
		)
		entry_manager.add(entry)
	
	# Save session
	session_manager.add(session)
	
	# Clear the workout data
	_clear_workout_data()
	
	return session

func _clear_workout_data() -> void:
	exercise_data.clear()
	program = null
	start_timestamp = 0
	end_timestamp = 0
	_is_active = false

func to_dict() -> Dictionary:
	"""Serialize the entire workout"""
	var serialized_exercises: Array = []
	for data in exercise_data:
		serialized_exercises.append(data.to_dict())
	
	return {
		"program_name": program.program_name if program else "",
		"start_timestamp": start_timestamp,
		"end_timestamp": end_timestamp,
		"is_active": _is_active,
		"exercise_data": serialized_exercises
	}

func from_dict(d: Dictionary, exercise_manager) -> void:
	"""Deserialize a saved workout"""
	_clear_workout_data()
	
	var program_name = str(d.get("program_name", ""))
	# Program will need to be resolved elsewhere
	
	start_timestamp = int(d.get("start_timestamp", 0))
	end_timestamp = int(d.get("end_timestamp", 0))
	_is_active = bool(d.get("is_active", false))
	
	var raw_exercises = d.get("exercise_data", [])
	if typeof(raw_exercises) == TYPE_ARRAY:
		for raw_data in raw_exercises:
			if typeof(raw_data) == TYPE_DICTIONARY:
				var data = WorkoutExerciseData.from_dict(raw_data, exercise_manager)
				if data:
					exercise_data.append(data)
	
	if _is_active:
		workout_started.emit()

# === Utility ===

func print_summary() -> void:
	print("=== WORKOUT SUMMARY ===")
	print("Program: %s" % (program.program_name if program else "None"))
	print("Duration: %d minutes" % get_duration_minutes())
	print("Total Volume: %.1f kg" % get_total_volume())
	print("Exercises: %d" % exercise_data.size())
	print("---")
	
	for i in range(exercise_data.size()):
		var data = exercise_data[i]
		var exercise_name = data.exercise.name if data.exercise else "Unknown"
		print("%d. %s" % [i + 1, exercise_name])
		print("   Sets: %d" % data.sets.size())
		print("   Total Volume: %.1f kg" % data.get_total_volume())
		print("   Max Weight: %.1f kg" % data.get_max_weight())
		for set_data in data.sets:
			print("     Set %d: %.1fkg x %d reps" % [set_data["order"] + 1, set_data["weight"], set_data["reps"]])
	print("======================")
