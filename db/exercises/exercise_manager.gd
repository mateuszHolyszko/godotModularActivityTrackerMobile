class_name ExerciseManager
extends RefCounted

const FILE_EXTENSION := ".json"

# items is an array of dictionaries: {"exercise": Exercise, "file_name": String}
var items: Array = []
var base_directory: String = ""
var exercises_directory: String = ""

func setup(base_dir: String) -> void:
	base_directory = base_dir
	exercises_directory = base_dir + "exercises/"
	
	# Create the exercises directory if it doesn't exist
	var dir := DirAccess.open(base_directory)
	if dir and not dir.dir_exists("exercises"):
		dir.make_dir("exercises")

func load() -> void:
	items.clear()
	
	var dir := DirAccess.open(exercises_directory)
	if not dir:
		push_error("ExerciseManager: failed to open directory %s" % exercises_directory)
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(FILE_EXTENSION):
			var file_path := exercises_directory + file_name
			var exercise := load_exercise_file(file_path)
			if exercise:
				items.append({"exercise": exercise, "file_name": file_name})
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Sort by filename for deterministic order
	items.sort_custom(func(a, b): return a["file_name"] < b["file_name"])

func load_exercise_file(file_path: String) -> Exercise:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("ExerciseManager: failed to read %s" % file_path)
		return null
	
	var text := file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return Exercise.from_dict(parsed)
	else:
		push_error("ExerciseManager: invalid exercise data in %s" % file_path)
		return null

func _sanitize_name_for_filename(name: String) -> String:
	var safe_name := name.strip_edges().replace(" ", "_").to_lower()
	safe_name = safe_name.replace("/", "_").replace("\\", "_").replace(":", "_")
	return safe_name

func _create_unique_filename(base_name: String) -> String:
	var candidate := base_name + FILE_EXTENSION
	var i := 1
	while FileAccess.file_exists(exercises_directory + candidate):
		candidate = "%s_%d%s" % [base_name, i, FILE_EXTENSION]
		i += 1
	return candidate

func save_exercise_file(exercise: Exercise) -> String:
	var safe_name := _sanitize_name_for_filename(exercise.name)
	if safe_name == "":
		safe_name = "exercise"
	var file_name := _create_unique_filename(safe_name)
	var file_path := exercises_directory + file_name
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(exercise.to_dict(), "\t"))
		file.close()
		return file_name
	else:
		push_error("ExerciseManager: failed to write %s (err %d)" % [file_path, FileAccess.get_open_error()])
		return ""

func change_note(exercise: Exercise, new_note: String) -> bool:
	if not exercise:
		push_error("ExerciseManager.change_note: exercise cannot be null")
		return false

	for item in items:
		if item.get("exercise") != exercise:
			continue

		var file_name: String = item.get("file_name", "")
		if file_name.is_empty():
			push_error("ExerciseManager.change_note: exercise has no file name")
			return false

		exercise.note = new_note
		var file_path := exercises_directory + file_name
		var file := FileAccess.open(file_path, FileAccess.WRITE)
		if not file:
			push_error("ExerciseManager: failed to update %s (err %d)" % [file_path, FileAccess.get_open_error()])
			return false

		file.store_string(JSON.stringify(exercise.to_dict(), "\t"))
		file.close()
		return true

	push_error("ExerciseManager.change_note: exercise not found")
	return false

func add(e: Exercise) -> void:
	# Save file and track filename
	var file_name := save_exercise_file(e)
	items.append({"exercise": e, "file_name": file_name})
	# Sort after adding
	items.sort_custom(func(a, b): return a["file_name"] < b["file_name"])

func remove_at(index: int) -> void:
	if index < 0 or index >= items.size():
		return
	
	var item = items[index]
	var file_name = item.get("file_name", "")
	if file_name != "":
		var full_path = exercises_directory + file_name
		if FileAccess.file_exists(full_path):
			var dir := DirAccess.open(exercises_directory)
			if dir:
				dir.remove(file_name)
	
	items.remove_at(index)
	
func remove_exercise(exercise_name: String) -> bool:
	"""
	Removes an exercise by its name (case-insensitive).
	Returns true if exercise was found and removed, false otherwise.
	"""
	if exercise_name.strip_edges() == "":
		push_error("ExerciseManager.remove_exercise: exercise name cannot be empty")
		return false
	
	var search_name := exercise_name.strip_edges().to_lower()
	
	# Find the exercise by name
	for i in range(items.size()):
		var item = items[i]
		var exercise: Exercise = item.get("exercise")
		if exercise and exercise.name.to_lower() == search_name:
			# Remove the file
			var file_name = item.get("file_name", "")
			if file_name != "":
				var full_path = exercises_directory + file_name
				if FileAccess.file_exists(full_path):
					var dir := DirAccess.open(exercises_directory)
					if dir:
						dir.remove(file_name)
			
			# Remove from items array
			items.remove_at(i)
			print("ExerciseManager: Removed exercise '%s'" % exercise.name)
			return true
	
	print("ExerciseManager: Exercise '%s' not found" % exercise_name)
	return false

func remove_all() -> void:
	var dir := DirAccess.open(exercises_directory)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(FILE_EXTENSION):
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	items.clear()

func add_exercise(
	name: String,
	target_muscle: String,
	bodyweight: bool,
	rep_range_min: int,
	rep_range_max: int,
	secondary_targets: Dictionary = {},
	modality: String = "",
	modifiers: Array[String] = []
) -> bool:
	# Validate inputs
	if name.strip_edges() == "":
		push_error("ExerciseManager.add_exercise: exercise name cannot be empty")
		return false
	
	if target_muscle.strip_edges() == "":
		push_error("ExerciseManager.add_exercise: target muscle cannot be empty")
		return false
	
	if not target_muscle in MuscleDict.MUSCLE_COLORS.keys():
		push_error("ExerciseManager.add_exercise: invalid target_muscle '%s'" % target_muscle)
		return false
	
	if rep_range_min < 0 or rep_range_max < 0:
		push_error("ExerciseManager.add_exercise: rep range values must be non-negative")
		return false
	
	if rep_range_min > rep_range_max:
		push_error("ExerciseManager.add_exercise: min reps (%d) cannot be greater than max reps (%d)" % [rep_range_min, rep_range_max])
		return false

	# Validate secondary_targets: { muscle: String -> fraction: float (0-1) }
	for muscle in secondary_targets.keys():
		if not (muscle is String) or not muscle in MuscleDict.MUSCLE_COLORS.keys():
			push_error("ExerciseManager.add_exercise: invalid secondary target muscle '%s'" % str(muscle))
			return false
		var fraction = secondary_targets[muscle]
		if typeof(fraction) != TYPE_FLOAT and typeof(fraction) != TYPE_INT:
			push_error("ExerciseManager.add_exercise: secondary target fraction for '%s' must be a number" % muscle)
			return false
		if fraction < 0.0 or fraction > 1.0:
			push_error("ExerciseManager.add_exercise: secondary target fraction for '%s' must be between 0 and 1" % muscle)
			return false

	# Validate modality
	if modality != "" and not modality in Exercise.MODALITIES:
		push_error("ExerciseManager.add_exercise: invalid modality '%s'" % modality)
		return false

	# Validate modifiers: valid values, at most one per category
	var seen_categories := {}
	for m in modifiers:
		var category := Exercise.get_modifier_category(m)
		if category == "":
			push_error("ExerciseManager.add_exercise: invalid modifier '%s'" % m)
			return false
		if seen_categories.has(category):
			push_error("ExerciseManager.add_exercise: multiple modifiers given for category '%s'" % category)
			return false
		seen_categories[category] = true
	
	# Create exercise resource
	var exercise := Exercise.new()
	exercise.name = name.strip_edges()
	exercise.note = ""
	exercise.target_muscle = target_muscle.strip_edges()
	exercise.bodyweight = bodyweight
	exercise.rep_range = Vector2i(rep_range_min, rep_range_max)
	exercise.secondary_targets = secondary_targets.duplicate()
	exercise.modality = modality
	exercise.modifiers = modifiers.duplicate()
	
	# Save and track the exercise
	add(exercise)
	
	print("ExerciseManager: Added exercise '%s' (muscle: %s, bodyweight: %s, reps: %d-%d, modality: %s, modifiers: %s, secondary_targets: %s)" % [exercise.name, exercise.target_muscle, str(exercise.bodyweight), rep_range_min, rep_range_max, (modality if modality != "" else "-"), str(exercise.modifiers), str(exercise.secondary_targets)])
	return true


func get_exercises() -> Array:
	"""
	Returns an array of all exercise dictionaries in the manager.
	Each dictionary contains: {"exercise": Exercise, "file_name": String}
	"""
	return items.duplicate()

func get_exercise(exercise_name: String) -> Exercise:
	"""
	Finds and returns an Exercise resource by its name (case-insensitive).
	Returns null if no exercise with the given name is found.
	"""
	if exercise_name.strip_edges() == "":
		push_error("ExerciseManager.get_exercise: exercise name cannot be empty")
		return null
	
	var search_name := exercise_name.strip_edges().to_lower()
	
	for item in items:
		var exercise: Exercise = item.get("exercise")
		if exercise and exercise.name.to_lower() == search_name:
			return exercise
	
	return null

func get_exercises_for_target(target_muscle: String) -> Array:
	"""
	Returns an array of exercise dictionaries filtered by target muscle.
	Each dictionary contains: {"exercise": Exercise, "file_name": String}
	Returns empty array if no exercises match or if target_muscle is invalid.
	"""
	if target_muscle.strip_edges() == "":
		push_error("ExerciseManager.get_exercises_for_target: target muscle cannot be empty")
		return []
	
	if not target_muscle in MuscleDict.MUSCLE_COLORS.keys():
		push_error("ExerciseManager.get_exercises_for_target: invalid target_muscle '%s'" % target_muscle)
		return []
	
	var filtered_items: Array = []
	var search_muscle := target_muscle.strip_edges()
	
	for item in items:
		var exercise: Exercise = item.get("exercise")
		if exercise and exercise.target_muscle == search_muscle:
			filtered_items.append(item)
	
	return filtered_items

func get_exercise_target_muscle(exercise_name: String) -> String:
	"""
	Gets the target muscle for a given exercise name (case-insensitive).
	Returns the target muscle string, or an empty string if exercise not found.
	"""
	if exercise_name.strip_edges() == "":
		push_error("ExerciseManager.get_exercise_target_muscle: exercise name cannot be empty")
		return ""
	
	var search_name := exercise_name.strip_edges().to_lower()
	
	for item in items:
		var exercise: Exercise = item.get("exercise")
		if exercise and exercise.name.to_lower() == search_name:
			return exercise.target_muscle
	
	print("ExerciseManager: Exercise '%s' not found" % exercise_name)
	return ""

func get_exercise_objects_for_target(target_muscle: String) -> Array[Exercise]:
	"""
	Returns an array of Exercise objects directly (not dictionaries) filtered by target muscle.
	"""
	var filtered: Array[Exercise] = []
	var items = get_exercises_for_target(target_muscle)
	
	for item in items:
		var exercise: Exercise = item.get("exercise")
		if exercise:
			filtered.append(exercise)
	
	return filtered

func get_exercises_for_modality(modality: String) -> Array[Exercise]:
	"""
	Returns Exercise objects whose modality matches (case-sensitive, must be a value from
	Exercise.MODALITIES). Returns empty array if modality is invalid or nothing matches.
	"""
	if modality.strip_edges() == "" or not modality in Exercise.MODALITIES:
		push_error("ExerciseManager.get_exercises_for_modality: invalid modality '%s'" % modality)
		return []

	var filtered: Array[Exercise] = []
	for item in items:
		var exercise: Exercise = item.get("exercise")
		if exercise and exercise.modality == modality:
			filtered.append(exercise)
	return filtered

func get_exercises_with_secondary_target(muscle: String) -> Array[Exercise]:
	"""
	Returns Exercise objects that list `muscle` among their secondary_targets (any fraction).
	"""
	if muscle.strip_edges() == "" or not muscle in MuscleDict.MUSCLE_COLORS.keys():
		push_error("ExerciseManager.get_exercises_with_secondary_target: invalid muscle '%s'" % muscle)
		return []

	var filtered: Array[Exercise] = []
	for item in items:
		var exercise: Exercise = item.get("exercise")
		if exercise and exercise.secondary_targets.has(muscle):
			filtered.append(exercise)
	return filtered

func get_exercises_with_modifier(modifier_value: String) -> Array[Exercise]:
	"""
	Returns Exercise objects that have `modifier_value` set (must be a value from
	Exercise.MODIFIER_CATEGORIES).
	"""
	if Exercise.get_modifier_category(modifier_value) == "":
		push_error("ExerciseManager.get_exercises_with_modifier: invalid modifier '%s'" % modifier_value)
		return []

	var filtered: Array[Exercise] = []
	for item in items:
		var exercise: Exercise = item.get("exercise")
		if exercise and modifier_value in exercise.modifiers:
			filtered.append(exercise)
	return filtered

func get_all_exercise_objects() -> Array[Exercise]:
	"""
	Returns an array of all Exercise objects directly (not dictionaries).
	"""
	var exercises: Array[Exercise] = []
	
	for item in items:
		var exercise: Exercise = item.get("exercise")
		if exercise:
			exercises.append(exercise)
	
	return exercises



func print_exercises() -> void:
	if items.is_empty():
		print("ExerciseManager: no exercises stored.")
		return
	print("ExerciseManager: %d exercise(s)" % items.size())
	for item in items:
		var e: Exercise = item["exercise"]
		var rr = e.rep_range

		var secondary_str := "-"
		if not e.secondary_targets.is_empty():
			var parts: Array[String] = []
			for muscle in e.secondary_targets.keys():
				parts.append("%s:%.2f" % [muscle, e.secondary_targets[muscle]])
			secondary_str = ", ".join(parts)

		var modality_str := e.modality if e.modality != "" else "-"
		var modifiers_str := ", ".join(e.modifiers) if not e.modifiers.is_empty() else "-"

		print("%s -> muscle:%s bodyweight:%s rep_range:%dx%d modality:%s modifiers:[%s] secondary:[%s]" % [
			e.name, e.target_muscle, str(e.bodyweight), rr.x, rr.y, modality_str, modifiers_str, secondary_str
		])

func seed_example_data() -> void:
	remove_all()
	var names := ["pushup", "squat", "bench press", "deadlift", "pullup"]
	var muscles := MuscleDict.MUSCLE_COLORS.keys()
	
	for i in range(5):
		var ex := Exercise.new()
		ex.name = names[i % names.size()]
		ex.note = ""
		ex.target_muscle = muscles[i % muscles.size()]
		ex.bodyweight = (ex.name == "pushup" or ex.name == "pullup")
		ex.rep_range = Vector2i(5 + (i % 5), 8 + (i % 6))

		# Sprinkle in the optional fields on a couple of entries so seeded data
		# also exercises secondary_targets / modality / modifiers end-to-end.
		match ex.name:
			"bench press":
				ex.modality = "barbell"
				ex.set_modifier("incline")
				if muscles.size() > i + 1:
					ex.set_secondary_target(muscles[(i + 1) % muscles.size()], 0.4)
			"squat":
				ex.modality = "barbell"
				ex.set_modifier("unilateral")
			"pushup":
				ex.modality = "calisthenics"
				ex.set_modifier("feet_elevated")

		add(ex)
	print("ExerciseManager: Seeded %d example exercises" % items.size())
