class_name ProgramManager
extends RefCounted

# Signal emitted whenever any program data changes
signal programs_changed()

const FILE_EXTENSION := ".json"

# items is an array of dictionaries: {"program": Program, "file_name": String}
var items: Array = []
var base_directory: String = ""
var programs_directory: String = ""

func setup(base_dir: String) -> void:
	base_directory = base_dir
	programs_directory = base_dir + "programs/"

	var dir := DirAccess.open(base_directory)
	if dir and not dir.dir_exists("programs"):
		dir.make_dir("programs")

func load() -> void:
	items.clear()

	var dir := DirAccess.open(programs_directory)
	if not dir:
		push_error("ProgramManager: failed to open directory %s" % programs_directory)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(FILE_EXTENSION):
			var file_path := programs_directory + file_name
			var program := load_program_file(file_path)
			if program:
				items.append({"program": program, "file_name": file_name})

		file_name = dir.get_next()

	dir.list_dir_end()

	items.sort_custom(func(a, b): return a["file_name"] < b["file_name"])
	
	programs_changed.emit()

func load_program_file(file_path: String) -> Program:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("ProgramManager: failed to read %s" % file_path)
		return null

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return Program.from_dict(parsed)
	else:
		push_error("ProgramManager: invalid program data in %s" % file_path)
		return null

func _sanitize_name_for_filename(name: String) -> String:
	var safe_name := name.strip_edges().replace(" ", "_").to_lower()
	safe_name = safe_name.replace("/", "_").replace("\\", "_").replace(":", "_")
	return safe_name

func _create_unique_filename(base_name: String) -> String:
	var candidate := base_name + FILE_EXTENSION
	var i := 1
	while FileAccess.file_exists(programs_directory + candidate):
		candidate = "%s_%d%s" % [base_name, i, FILE_EXTENSION]
		i += 1
	return candidate

func save_program_file(program: Program) -> String:
	var safe_name := _sanitize_name_for_filename(program.program_name)
	if safe_name == "":
		safe_name = "program"
	var file_name := _create_unique_filename(safe_name)
	var file_path := programs_directory + file_name
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(program.to_dict(), "\t"))
		file.close()
		return file_name
	else:
		push_error("ProgramManager: failed to write %s (err %d)" % [file_path, FileAccess.get_open_error()])
		return ""

func add(p: Program) -> void:
	var file_name := save_program_file(p)
	items.append({"program": p, "file_name": file_name})
	items.sort_custom(func(a, b): return a["file_name"] < b["file_name"])
	
	programs_changed.emit()

func remove_at(index: int) -> void:
	if index < 0 or index >= items.size():
		return

	var item = items[index]
	var file_name = item.get("file_name", "")
	if file_name != "":
		var full_path = programs_directory + file_name
		if FileAccess.file_exists(full_path):
			var dir := DirAccess.open(programs_directory)
			if dir:
				dir.remove(file_name)

	items.remove_at(index)
	
	programs_changed.emit()

func remove_program(program_name: String) -> bool:
	if program_name.strip_edges() == "":
		push_error("ProgramManager.remove_program: program name cannot be empty")
		return false

	var search_name := program_name.strip_edges().to_lower()

	for i in range(items.size()):
		var item = items[i]
		var program: Program = item.get("program")
		if program and program.program_name.to_lower() == search_name:
			var file_name = item.get("file_name", "")
			if file_name != "":
				var full_path = programs_directory + file_name
				if FileAccess.file_exists(full_path):
					var dir := DirAccess.open(programs_directory)
					if dir:
						dir.remove(file_name)

			items.remove_at(i)
			print("ProgramManager: Removed program '%s'" % program.program_name)
			
			programs_changed.emit()
			return true

	print("ProgramManager: Program '%s' not found" % program_name)
	return false

func remove_all() -> void:
	var dir := DirAccess.open(programs_directory)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(FILE_EXTENSION):
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

	items.clear()
	
	programs_changed.emit()

func rename_program(old_name: String, new_name: String) -> bool:
	"""
	Renames a program from old_name to new_name.
	Returns true if successful, false otherwise.
	"""
	if old_name.strip_edges() == "":
		push_error("ProgramManager.rename_program: old program name cannot be empty")
		return false
	
	if new_name.strip_edges() == "":
		push_error("ProgramManager.rename_program: new program name cannot be empty")
		return false
	
	var old_name_clean := old_name.strip_edges()
	var new_name_clean := new_name.strip_edges()
	
	# Check if new name already exists (case-insensitive)
	var existing := get_program(new_name_clean)
	if existing:
		push_error("ProgramManager.rename_program: program '%s' already exists" % new_name_clean)
		return false
	
	# Find the program item
	var program_item := _get_program_item(old_name_clean)
	if program_item.is_empty():
		push_error("ProgramManager.rename_program: program '%s' not found" % old_name_clean)
		return false
	
	var program: Program = program_item["program"]
	var old_file_name: String = program_item.get("file_name", "")
	
	if old_file_name == "":
		push_error("ProgramManager.rename_program: no file name found for program '%s'" % old_name_clean)
		return false
	
	# Update the program name
	program.program_name = new_name_clean
	
	# Create a new file with the new name
	var new_file_name := save_program_file(program)
	if new_file_name == "":
		push_error("ProgramManager.rename_program: failed to save program with new name")
		# Revert the name change
		program.program_name = old_name_clean
		return false
	
	# Delete the old file
	var old_full_path := programs_directory + old_file_name
	if FileAccess.file_exists(old_full_path):
		var dir := DirAccess.open(programs_directory)
		if dir:
			dir.remove(old_file_name)
	
	# Update the item with the new file name
	program_item["file_name"] = new_file_name
	
	print("ProgramManager: Renamed program '%s' to '%s'" % [old_name_clean, new_name_clean])
	
	programs_changed.emit()
	return true

func add_program(name: String) -> Program:
	if name.strip_edges() == "":
		push_error("ProgramManager.add_program: program name cannot be empty")
		return null

	var program := Program.new()
	program.program_name = name.strip_edges()
	add(program)

	print("ProgramManager: Added program '%s'" % program.program_name)
	
	# Signal already emitted in add()
	return program

func get_programs() -> Array:
	return items.duplicate()

func get_program(program_name: String) -> Program:
	if program_name.strip_edges() == "":
		push_error("ProgramManager.get_program: program name cannot be empty")
		return null

	var search_name := program_name.strip_edges().to_lower()

	for item in items:
		var program: Program = item.get("program")
		if program and program.program_name.to_lower() == search_name:
			return program

	return null

func get_all_program_objects() -> Array[Program]:
	var programs: Array[Program] = []
	for item in items:
		var program: Program = item.get("program")
		if program:
			programs.append(program)
	return programs


func get_program_target_breakdown(program: Program) -> Dictionary:
	"""
	Calculates the target muscle breakdown for a program.
	For each exercise in the program, it looks up the target muscle from ExerciseManager
	and counts how many exercises target each muscle.
	
	Returns a Dictionary like: {"Chest": 2, "Biceps": 1, "Quads": 4, ...}
	"""
	if not program:
		push_error("ProgramManager.get_program_target_breakdown: program is null")
		return {}
	
	var breakdown: Dictionary = {}
	
	# Initialize all muscles with 0 count
	for muscle in MuscleDict.get_all_muscles():
		breakdown[muscle] = 0
	
	# Iterate through all items in the program
	for item in program.items:
		var item_type = item.get("type", "")
		
		if item_type == "exercise":
			var exercise_name = item.get("exercise_name", "")
			if exercise_name.is_empty():
				continue
			
			# Get the exercise from ExerciseManager
			var exercise = DataManager.ExerciseManager.get_exercise(exercise_name)
			if exercise:
				var target_muscle = exercise.target_muscle
				if target_muscle in breakdown:
					breakdown[target_muscle] += 1
				else:
					# If muscle not in dictionary (shouldn't happen with proper data)
					breakdown[target_muscle] = 1
			else:
				# Exercise not found, log a warning
				print("ProgramManager: Exercise '%s' not found in ExerciseManager" % exercise_name)
				
		elif item_type == "superset":
			# For supersets, count each exercise in the superset
			var exercise_names = item.get("exercise_names", [])
			for exercise_name in exercise_names:
				if exercise_name.is_empty():
					continue
				
				var exercise = DataManager.ExerciseManager.get_exercise(exercise_name)
				if exercise:
					var target_muscle = exercise.target_muscle
					if target_muscle in breakdown:
						breakdown[target_muscle] += 1
					else:
						breakdown[target_muscle] = 1
				else:
					print("ProgramManager: Exercise '%s' not found in ExerciseManager (in superset)" % exercise_name)
	
	# Remove any muscles with 0 count for a cleaner result
	var result: Dictionary = {}
	for muscle in breakdown:
		if breakdown[muscle] > 0:
			result[muscle] = breakdown[muscle]
	
	return result

# Optional: Add a convenience function that takes a program name instead
func get_program_target_breakdown_by_name(program_name: String) -> Dictionary:
	"""
	Gets the target breakdown for a program by its name.
	"""
	if program_name.strip_edges() == "":
		push_error("ProgramManager.get_program_target_breakdown_by_name: program name cannot be empty")
		return {}
	
	var program = get_program(program_name)
	if not program:
		push_error("ProgramManager.get_program_target_breakdown_by_name: program '%s' not found" % program_name)
		return {}
	
	return get_program_target_breakdown(program)

#region item array mutations
# --- internal helpers ---------------------------------------------------

func _get_program_item(program_name: String) -> Dictionary:
	"""
	Returns the {"program": Program, "file_name": String} entry for the given
	program name (case-insensitive), or an empty Dictionary if not found.
	"""
	var search_name := program_name.strip_edges().to_lower()
	for item in items:
		var program: Program = item.get("program")
		if program and program.program_name.to_lower() == search_name:
			return item
	return {}

func _persist(program_item: Dictionary) -> bool:
	"""
	Re-writes the program's existing file (does not rename/create a new file).
	"""
	var program: Program = program_item.get("program")
	var file_name: String = program_item.get("file_name", "")
	if not program or file_name == "":
		push_error("ProgramManager: cannot persist, missing program or file_name")
		return false

	var file_path := programs_directory + file_name
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		push_error("ProgramManager: failed to write %s (err %d)" % [file_path, FileAccess.get_open_error()])
		return false

	file.store_string(JSON.stringify(program.to_dict(), "\t"))
	file.close()
	return true

func _get_superset_at(program: Program, superset_index: int) -> Dictionary:
	"""
	Returns the superset item dict at superset_index if it exists and is a
	superset, or an empty Dictionary otherwise.
	"""
	if superset_index < 0 or superset_index >= program.items.size():
		push_error("ProgramManager: superset index %d out of bounds" % superset_index)
		return {}
	var item = program.items[superset_index]
	if item.get("type") != "superset":
		push_error("ProgramManager: item at index %d is not a superset" % superset_index)
		return {}
	return item

func _emit_if_changed(result: bool) -> void:
	"""
	Helper to emit programs_changed if the operation was successful.
	"""
	if result:
		programs_changed.emit()

# --- top-level items[] editing ------------------------------------------

func move_program_item(program_name: String, from_index: int, to_index: int) -> bool:
	var program_item := _get_program_item(program_name)
	if program_item.is_empty():
		push_error("ProgramManager.move_program_item: program '%s' not found" % program_name)
		return false

	var program: Program = program_item["program"]
	if from_index < 0 or from_index >= program.items.size():
		push_error("ProgramManager.move_program_item: from_index %d out of bounds" % from_index)
		return false
	if to_index < 0 or to_index >= program.items.size():
		push_error("ProgramManager.move_program_item: to_index %d out of bounds" % to_index)
		return false

	var entry = program.items[from_index]
	program.items.remove_at(from_index)
	program.items.insert(to_index, entry)

	var result = _persist(program_item)
	_emit_if_changed(result)
	return result

func add_exercise_item_at(program_name: String, index: int, exercise_name: String) -> bool:
	var program_item := _get_program_item(program_name)
	if program_item.is_empty():
		push_error("ProgramManager.add_exercise_item_at: program '%s' not found" % program_name)
		return false
	if exercise_name.strip_edges() == "":
		push_error("ProgramManager.add_exercise_item_at: exercise name cannot be empty")
		return false

	var program: Program = program_item["program"]
	if index < 0 or index > program.items.size():
		push_error("ProgramManager.add_exercise_item_at: index %d out of bounds" % index)
		return false

	program.items.insert(index, {"type": "exercise", "exercise_name": exercise_name.strip_edges()})
	var result = _persist(program_item)
	_emit_if_changed(result)
	return result

func add_superset_item_at(program_name: String, index: int, exercise_names: Array) -> bool:
	var program_item := _get_program_item(program_name)
	if program_item.is_empty():
		push_error("ProgramManager.add_superset_item_at: program '%s' not found" % program_name)
		return false

	var program: Program = program_item["program"]
	if index < 0 or index > program.items.size():
		push_error("ProgramManager.add_superset_item_at: index %d out of bounds" % index)
		return false

	var names: Array = []
	for n in exercise_names:
		if str(n).strip_edges() != "":
			names.append(str(n).strip_edges())

	program.items.insert(index, {"type": "superset", "exercise_names": names})
	var result = _persist(program_item)
	_emit_if_changed(result)
	return result

func replace_item_with_exercise(program_name: String, index: int, exercise_name: String) -> bool:
	var program_item := _get_program_item(program_name)
	if program_item.is_empty():
		push_error("ProgramManager.replace_item_with_exercise: program '%s' not found" % program_name)
		return false
	if exercise_name.strip_edges() == "":
		push_error("ProgramManager.replace_item_with_exercise: exercise name cannot be empty")
		return false

	var program: Program = program_item["program"]
	if index < 0 or index >= program.items.size():
		push_error("ProgramManager.replace_item_with_exercise: index %d out of bounds" % index)
		return false

	program.items[index] = {"type": "exercise", "exercise_name": exercise_name.strip_edges()}
	var result = _persist(program_item)
	_emit_if_changed(result)
	return result

func replace_item_with_superset(program_name: String, index: int, exercise_names: Array) -> bool:
	var program_item := _get_program_item(program_name)
	if program_item.is_empty():
		push_error("ProgramManager.replace_item_with_superset: program '%s' not found" % program_name)
		return false

	var program: Program = program_item["program"]
	if index < 0 or index >= program.items.size():
		push_error("ProgramManager.replace_item_with_superset: index %d out of bounds" % index)
		return false

	var names: Array = []
	for n in exercise_names:
		if str(n).strip_edges() != "":
			names.append(str(n).strip_edges())

	program.items[index] = {"type": "superset", "exercise_names": names}
	var result = _persist(program_item)
	_emit_if_changed(result)
	return result

func remove_program_item_at(program_name: String, index: int) -> bool:
	var program_item := _get_program_item(program_name)
	if program_item.is_empty():
		push_error("ProgramManager.remove_program_item_at: program '%s' not found" % program_name)
		return false

	var program: Program = program_item["program"]
	if index < 0 or index >= program.items.size():
		push_error("ProgramManager.remove_program_item_at: index %d out of bounds" % index)
		return false

	program.items.remove_at(index)
	var result = _persist(program_item)
	_emit_if_changed(result)
	return result


# --- superset sub-items editing (exercise_names[] within a superset) ----

func move_superset_exercise(program_name: String, superset_index: int, from_index: int, to_index: int) -> bool:
	var program_item := _get_program_item(program_name)
	if program_item.is_empty():
		push_error("ProgramManager.move_superset_exercise: program '%s' not found" % program_name)
		return false

	var program: Program = program_item["program"]
	var superset := _get_superset_at(program, superset_index)
	if superset.is_empty():
		return false

	var names: Array = superset["exercise_names"]
	if from_index < 0 or from_index >= names.size():
		push_error("ProgramManager.move_superset_exercise: from_index %d out of bounds" % from_index)
		return false
	if to_index < 0 or to_index >= names.size():
		push_error("ProgramManager.move_superset_exercise: to_index %d out of bounds" % to_index)
		return false

	var name = names[from_index]
	names.remove_at(from_index)
	names.insert(to_index, name)

	var result = _persist(program_item)
	_emit_if_changed(result)
	return result

func add_superset_exercise_at(program_name: String, superset_index: int, index: int, exercise_name: String) -> bool:
	var program_item := _get_program_item(program_name)
	if program_item.is_empty():
		push_error("ProgramManager.add_superset_exercise_at: program '%s' not found" % program_name)
		return false
	if exercise_name.strip_edges() == "":
		push_error("ProgramManager.add_superset_exercise_at: exercise name cannot be empty")
		return false

	var program: Program = program_item["program"]
	var superset := _get_superset_at(program, superset_index)
	if superset.is_empty():
		return false

	var names: Array = superset["exercise_names"]
	if index < 0 or index > names.size():
		push_error("ProgramManager.add_superset_exercise_at: index %d out of bounds" % index)
		return false

	names.insert(index, exercise_name.strip_edges())
	var result = _persist(program_item)
	_emit_if_changed(result)
	return result

func replace_superset_exercise_at(program_name: String, superset_index: int, index: int, exercise_name: String) -> bool:
	var program_item := _get_program_item(program_name)
	if program_item.is_empty():
		push_error("ProgramManager.replace_superset_exercise_at: program '%s' not found" % program_name)
		return false
	if exercise_name.strip_edges() == "":
		push_error("ProgramManager.replace_superset_exercise_at: exercise name cannot be empty")
		return false

	var program: Program = program_item["program"]
	var superset := _get_superset_at(program, superset_index)
	if superset.is_empty():
		return false

	var names: Array = superset["exercise_names"]
	if index < 0 or index >= names.size():
		push_error("ProgramManager.replace_superset_exercise_at: index %d out of bounds" % index)
		return false

	names[index] = exercise_name.strip_edges()
	var result = _persist(program_item)
	_emit_if_changed(result)
	return result

func remove_superset_exercise_at(program_name: String, superset_index: int, index: int) -> bool:
	var program_item := _get_program_item(program_name)
	if program_item.is_empty():
		push_error("ProgramManager.remove_superset_exercise_at: program '%s' not found" % program_name)
		return false

	var program: Program = program_item["program"]
	var superset := _get_superset_at(program, superset_index)
	if superset.is_empty():
		return false

	var names: Array = superset["exercise_names"]
	if index < 0 or index >= names.size():
		push_error("ProgramManager.remove_superset_exercise_at: index %d out of bounds" % index)
		return false

	names.remove_at(index)
	var result = _persist(program_item)
	_emit_if_changed(result)
	return result
#endregion


func seed_example_programs() -> void:
	remove_all()

	# Program A: straightforward list, no supersets
	var program_a := add_program("Full Body A")
	if program_a:
		program_a.add_exercise("squat")
		program_a.add_exercise("bench press")
		program_a.add_exercise("deadlift")
		_persist(_get_program_item(program_a.program_name))

	# Program B: opens and closes with single exercises, superset in the middle
	var program_b := add_program("Push Pull B")
	if program_b:
		program_b.add_exercise("pushup")
		program_b.add_superset(["pullup", "bench press"])
		program_b.add_exercise("deadlift")
		_persist(_get_program_item(program_b.program_name))

	# Program C: two supersets back to back
	var program_c := add_program("Superset Circuit")
	if program_c:
		program_c.add_superset(["pushup", "squat"])
		program_c.add_superset(["pullup", "deadlift"])
		program_c.add_exercise("bench press")
		_persist(_get_program_item(program_c.program_name))

	print("ProgramManager: Seeded %d example programs" % items.size())
	
	# remove_all already emitted, but subsequent additions will emit too

func print_all_programs() -> void:
	if items.is_empty():
		print("ProgramManager: no programs stored.")
		return
	print("ProgramManager: %d program(s)" % items.size())
	for item in items:
		var program: Program = item["program"]
		print("- %s (%d item(s))" % [program.program_name, program.items.size()])

func print_program(program_name: String) -> void:
	var program_item := _get_program_item(program_name)
	if program_item.is_empty():
		print("ProgramManager: Program '%s' not found" % program_name)
		return

	var program: Program = program_item["program"]
	print("Program: %s" % program.program_name)

	if program.items.is_empty():
		print("  (no items)")
		return

	for i in range(program.items.size()):
		var entry = program.items[i]
		if entry.get("type") == "exercise":
			print("  %d. %s" % [i + 1, entry.get("exercise_name", "")])
		elif entry.get("type") == "superset":
			var names: Array = entry.get("exercise_names", [])
			print("  %d. Superset: %s" % [i + 1, ", ".join(names)])
		else:
			print("  %d. <unknown item type>" % (i + 1))
