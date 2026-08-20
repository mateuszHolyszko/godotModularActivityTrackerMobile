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

func add_exercise(name: String, target_muscle: String, bodyweight: bool, rep_range_min: int, rep_range_max: int) -> bool:
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
	
	# Create exercise resource
	var exercise := Exercise.new()
	exercise.name = name.strip_edges()
	exercise.target_muscle = target_muscle.strip_edges()
	exercise.bodyweight = bodyweight
	exercise.rep_range = Vector2i(rep_range_min, rep_range_max)
	
	# Save and track the exercise
	add(exercise)
	
	print("ExerciseManager: Added exercise '%s' (muscle: %s, bodyweight: %s, reps: %d-%d)" % [exercise.name, exercise.target_muscle, str(exercise.bodyweight), rep_range_min, rep_range_max])
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
		var e = item["exercise"]
		var rr = e.rep_range
		print("%s -> muscle:%s bodyweight:%s rep_range:%dx%d" % [e.name, e.target_muscle, str(e.bodyweight), rr.x, rr.y])

func seed_example_data() -> void:
	remove_all()
	var names := ["pushup", "squat", "bench press", "deadlift", "pullup"]
	var muscles := MuscleDict.MUSCLE_COLORS.keys()
	
	for i in range(5):
		var ex := Exercise.new()
		ex.name = names[i % names.size()]
		ex.target_muscle = muscles[i % muscles.size()]
		ex.bodyweight = (ex.name == "pushup" or ex.name == "pullup")
		ex.rep_range = Vector2i(5 + (i % 5), 8 + (i % 6))
		add(ex)
	print("ExerciseManager: Seeded %d example exercises" % items.size())
