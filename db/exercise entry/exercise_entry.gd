extends Resource
class_name ExerciseEntry

# Reference to the exercise being performed
@export var exercise: Exercise
# Reference to the session this entry belongs to (optional, for context)
@export var session_id: String = ""  # Store session ID instead of full reference
# Array of set dictionaries: [{"order": int, "weight": float, "reps": int}, ...]
@export var sets: Array = []

func add_set(weight: float, reps: int) -> void:
	sets.append({
		"order": sets.size(),
		"weight": weight,
		"reps": reps
	})

func remove_set_at(index: int) -> void:
	if index < 0 or index >= sets.size():
		return
	sets.remove_at(index)
	# Reorder remaining sets
	for i in range(index, sets.size()):
		sets[i]["order"] = i

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
			"order": set_data.get("order", 0),
			"weight": set_data.get("weight", 0.0),
			"reps": set_data.get("reps", 0)
		})
	
	return {
		"exercise_name": exercise.name if exercise else "",
		"session_id": session_id,
		"sets": serialized_sets
	}

static func from_dict(d: Dictionary, exercise_manager) -> ExerciseEntry:
	var entry := ExerciseEntry.new()
	
	var exercise_name = str(d.get("exercise_name", ""))
	if exercise_name != "" and exercise_manager:
		entry.exercise = exercise_manager.get_exercise(exercise_name)
		if not entry.exercise:
			push_error("ExerciseEntry.from_dict: exercise '%s' not found" % exercise_name)
	
	entry.session_id = str(d.get("session_id", ""))
	
	var raw_sets = d.get("sets", [])
	if typeof(raw_sets) == TYPE_ARRAY:
		for raw_set in raw_sets:
			if typeof(raw_set) == TYPE_DICTIONARY:
				entry.sets.append({
					"order": int(raw_set.get("order", entry.sets.size())),
					"weight": float(raw_set.get("weight", 0.0)),
					"reps": int(raw_set.get("reps", 0))
				})
	
	return entry
