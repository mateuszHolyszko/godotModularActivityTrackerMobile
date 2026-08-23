class_name ExerciseEntryManager
extends RefCounted

const FILE_EXTENSION := ".json"
const ENTRIES_SUBDIR := "exercise_entries/"

# items is an array of dictionaries: {"entry": ExerciseEntry, "file_name": String}
var items: Array = []
var base_directory: String = ""
var entries_directory: String = ""

func setup(base_dir: String) -> void:
	base_directory = base_dir
	entries_directory = base_dir + ENTRIES_SUBDIR
	
	# Create the entries directory if it doesn't exist
	var dir := DirAccess.open(base_directory)
	if dir and not dir.dir_exists(ENTRIES_SUBDIR):
		dir.make_dir(ENTRIES_SUBDIR)

func load(exercise_manager) -> void:
	items.clear()
	
	var dir := DirAccess.open(entries_directory)
	if not dir:
		push_error("ExerciseEntryManager: failed to open directory %s" % entries_directory)
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(FILE_EXTENSION):
			var file_path := entries_directory + file_name
			var entry := load_entry_file(file_path, exercise_manager)
			if entry:
				items.append({"entry": entry, "file_name": file_name})
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Sort by exercise name for deterministic order
	items.sort_custom(func(a, b):
		var a_entry: ExerciseEntry = a["entry"]
		var b_entry: ExerciseEntry = b["entry"]
		var a_name = a_entry.exercise.name if a_entry.exercise else ""
		var b_name = b_entry.exercise.name if b_entry.exercise else ""
		return a_name < b_name
	)

func load_entry_file(file_path: String, exercise_manager) -> ExerciseEntry:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("ExerciseEntryManager: failed to read %s" % file_path)
		return null
	
	var text := file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return ExerciseEntry.from_dict(parsed, exercise_manager)
	else:
		push_error("ExerciseEntryManager: invalid entry data in %s" % file_path)
		return null

func _sanitize_name_for_filename(name: String) -> String:
	var safe_name := name.strip_edges().replace(" ", "_").to_lower()
	safe_name = safe_name.replace("/", "_").replace("\\", "_").replace(":", "_")
	return safe_name

func _create_unique_filename(base_name: String) -> String:
	var candidate := base_name + FILE_EXTENSION
	var i := 1
	while FileAccess.file_exists(entries_directory + candidate):
		candidate = "%s_%d%s" % [base_name, i, FILE_EXTENSION]
		i += 1
	return candidate

func save_entry_file(entry: ExerciseEntry) -> String:
	var exercise_name := entry.exercise.name if entry.exercise else "unknown_exercise"
	var safe_name := _sanitize_name_for_filename(exercise_name)
	var session_suffix := "_" + entry.session_id if entry.session_id != "" else ""
	var base_name := safe_name + session_suffix
	
	var file_name := _create_unique_filename(base_name)
	var file_path := entries_directory + file_name
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(entry.to_dict(), "\t"))
		file.close()
		return file_name
	else:
		push_error("ExerciseEntryManager: failed to write %s (err %d)" % [file_path, FileAccess.get_open_error()])
		return ""

func add(entry: ExerciseEntry) -> void:
	var file_name := save_entry_file(entry)
	items.append({"entry": entry, "file_name": file_name})
	
	# Sort after adding
	items.sort_custom(func(a, b):
		var a_entry: ExerciseEntry = a["entry"]
		var b_entry: ExerciseEntry = b["entry"]
		var a_name = a_entry.exercise.name if a_entry.exercise else ""
		var b_name = b_entry.exercise.name if b_entry.exercise else ""
		return a_name < b_name
	)

func remove_at(index: int) -> void:
	if index < 0 or index >= items.size():
		return
	
	var item = items[index]
	var file_name = item.get("file_name", "")
	if file_name != "":
		var full_path = entries_directory + file_name
		if FileAccess.file_exists(full_path):
			var dir := DirAccess.open(entries_directory)
			if dir:
				dir.remove(file_name)
	
	items.remove_at(index)

func remove_by_session_id(session_id: String) -> void:
	"""Remove all entries associated with a specific session ID"""
	var indices_to_remove: Array = []
	
	for i in range(items.size()):
		var entry: ExerciseEntry = items[i].get("entry")
		if entry and entry.session_id == session_id:
			indices_to_remove.append(i)
	
	# Remove from highest index to lowest to avoid shifting issues
	indices_to_remove.sort()
	for i in range(indices_to_remove.size() - 1, -1, -1):
		remove_at(indices_to_remove[i])

func remove_all() -> void:
	var dir := DirAccess.open(entries_directory)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(FILE_EXTENSION):
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	items.clear()

func get_entries() -> Array:
	"""Returns all entry dictionaries: [{"entry": ExerciseEntry, "file_name": String}]"""
	return items.duplicate()

func get_entries_by_session(session_id: String) -> Array[ExerciseEntry]:
	"""Get all entries belonging to a specific session"""
	var entries: Array[ExerciseEntry] = []
	
	for item in items:
		var entry: ExerciseEntry = item.get("entry")
		if entry and entry.session_id == session_id:
			entries.append(entry)
	
	return entries

func get_entries_by_exercise(exercise_name: String) -> Array[ExerciseEntry]:
	"""Get all entries for a specific exercise"""
	var entries: Array[ExerciseEntry] = []
	var search_name := exercise_name.strip_edges().to_lower()
	
	for item in items:
		var entry: ExerciseEntry = item.get("entry")
		if entry and entry.exercise and entry.exercise.name.to_lower() == search_name:
			entries.append(entry)
	
	return entries

func get_entry_objects() -> Array[ExerciseEntry]:
	"""Returns all ExerciseEntry objects directly"""
	var entries: Array[ExerciseEntry] = []
	for item in items:
		var entry: ExerciseEntry = item.get("entry")
		if entry:
			entries.append(entry)
	return entries

func create_entry(exercise: Exercise, session_id: String = "", sets_data: Array = []) -> ExerciseEntry:
	"""Convenience method to create a new exercise entry"""
	var entry := ExerciseEntry.new()
	entry.exercise = exercise
	entry.session_id = session_id
	
	for set_data in sets_data:
		if typeof(set_data) == TYPE_DICTIONARY:
			var weight = float(set_data.get("weight", 0.0))
			var reps = int(set_data.get("reps", 0))
			entry.add_set(weight, reps)
	
	return entry

func update_entry(entry: ExerciseEntry) -> void:
	"""Find and update an existing entry in the manager"""
	for i in range(items.size()):
		var item = items[i]
		var stored_entry: ExerciseEntry = item.get("entry")
		if stored_entry == entry:
			# Remove old file
			var old_file_name = item.get("file_name", "")
			if old_file_name != "":
				var full_path = entries_directory + old_file_name
				if FileAccess.file_exists(full_path):
					var dir := DirAccess.open(entries_directory)
					if dir:
						dir.remove(old_file_name)
			
			# Save with new file
			var new_file_name := save_entry_file(entry)
			items[i] = {"entry": entry, "file_name": new_file_name}
			
			# Resort
			items.sort_custom(func(a, b):
				var a_entry: ExerciseEntry = a["entry"]
				var b_entry: ExerciseEntry = b["entry"]
				var a_name = a_entry.exercise.name if a_entry.exercise else ""
				var b_name = b_entry.exercise.name if b_entry.exercise else ""
				return a_name < b_name
			)
			return
	
	push_error("ExerciseEntryManager: Entry not found in manager")

func print_entries() -> void:
	if items.is_empty():
		print("ExerciseEntryManager: no entries stored.")
		return
	
	print("ExerciseEntryManager: %d entry(s)" % items.size())
	for item in items:
		var entry = item["entry"]
		var exercise_name = entry.exercise.name if entry.exercise else "Unknown Exercise"
		var session_info = "Session: %s" % entry.session_id if entry.session_id != "" else "No Session"
		var sets_str = ""
		for set_data in entry.sets:
			sets_str += "[%dkg x %d] " % [set_data["weight"], set_data["reps"]]
		print("%s - %s - Sets: %s" % [exercise_name, session_info, sets_str.strip_edges()])

func seed_example_data(exercise_manager) -> void:
	"""Creates example exercise entries for testing"""
	remove_all()
	
	var exercises = exercise_manager.get_all_exercise_objects()
	if exercises.is_empty():
		print("ExerciseEntryManager: No exercises available to seed data")
		return
	
	var session_ids = ["session_001", "session_002", "session_003"]
	
	for session_id in session_ids:
		var num_entries = randi_range(3, 5)
		for i in range(num_entries):
			var exercise = exercises[i % exercises.size()]
			
			# Create entry with 3-4 sets
			var sets_data = []
			var num_sets = randi_range(3, 4)
			for j in range(num_sets):
				var weight = 20.0 + (j * 5.0) + (randi() % 10)
				var reps = 8 + randi_range(0, 4)
				sets_data.append({"weight": weight, "reps": reps})
			
			var entry = create_entry(exercise, session_id, sets_data)
			add(entry)
	
	print("ExerciseEntryManager: Seeded %d example entries" % items.size())
