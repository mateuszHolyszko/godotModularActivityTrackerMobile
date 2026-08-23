class_name SessionManager
extends RefCounted

const FILE_EXTENSION := ".json"
const SESSIONS_SUBDIR := "sessions/"

# items is an array of dictionaries: {"session": Session, "file_name": String}
var items: Array = []
var base_directory: String = ""
var sessions_directory: String = ""

func setup(base_dir: String) -> void:
	base_directory = base_dir
	sessions_directory = base_dir + SESSIONS_SUBDIR
	
	# Create the sessions directory if it doesn't exist
	var dir := DirAccess.open(base_directory)
	if dir and not dir.dir_exists(SESSIONS_SUBDIR):
		dir.make_dir(SESSIONS_SUBDIR)

func load(exercise_manager, entry_manager) -> void:
	items.clear()
	
	var dir := DirAccess.open(sessions_directory)
	if not dir:
		push_error("SessionManager: failed to open directory %s" % sessions_directory)
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(FILE_EXTENSION):
			var file_path := sessions_directory + file_name
			var session := load_session_file(file_path, exercise_manager, entry_manager)
			if session:
				items.append({"session": session, "file_name": file_name})
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Sort by date (newest first) and then by filename
	items.sort_custom(func(a, b):
		var a_session: Session = a["session"]
		var b_session: Session = b["session"]
		
		# Sort by date in descending order (newest first)
		if a_session.date != b_session.date:
			return a_session.date > b_session.date
		
		# If dates match, sort by filename
		return a["file_name"] < b["file_name"]
	)

func load_session_file(file_path: String, exercise_manager, entry_manager) -> Session:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("SessionManager: failed to read %s" % file_path)
		return null
	
	var text := file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return Session.from_dict(parsed, exercise_manager, entry_manager)
	else:
		push_error("SessionManager: invalid session data in %s" % file_path)
		return null

func _sanitize_name_for_filename(name: String) -> String:
	var safe_name := name.strip_edges().replace(" ", "_").to_lower()
	safe_name = safe_name.replace("/", "_").replace("\\", "_").replace(":", "_")
	return safe_name

func _create_unique_filename(base_name: String) -> String:
	var candidate := base_name + FILE_EXTENSION
	var i := 1
	while FileAccess.file_exists(sessions_directory + candidate):
		candidate = "%s_%d%s" % [base_name, i, FILE_EXTENSION]
		i += 1
	return candidate

func save_session_file(session: Session) -> String:
	# Create filename from date + program name + session_id
	var date_str := session.date
	if date_str == "":
		date_str = Time.get_date_string_from_system()
	
	var program_name := session.program.program_name if session.program else "unknown_program"
	var safe_program_name := _sanitize_name_for_filename(program_name)
	var base_name := "%s_%s_%s" % [date_str, safe_program_name, session.session_id]
	
	var file_name := _create_unique_filename(base_name)
	var file_path := sessions_directory + file_name
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(session.to_dict(), "\t"))
		file.close()
		return file_name
	else:
		push_error("SessionManager: failed to write %s (err %d)" % [file_path, FileAccess.get_open_error()])
		return ""

func add(session: Session) -> void:
	var file_name := save_session_file(session)
	items.append({"session": session, "file_name": file_name})
	
	# Sort after adding
	items.sort_custom(func(a, b):
		var a_session: Session = a["session"]
		var b_session: Session = b["session"]
		if a_session.date != b_session.date:
			return a_session.date > b_session.date
		# If same date, use session_id to determine order
		# session_id contains timestamp, so newer will have higher value
		return a_session.session_id > b_session.session_id
	)

func remove_at(index: int) -> void:
	if index < 0 or index >= items.size():
		return
	
	var item = items[index]
	var file_name = item.get("file_name", "")
	if file_name != "":
		var full_path = sessions_directory + file_name
		if FileAccess.file_exists(full_path):
			var dir := DirAccess.open(sessions_directory)
			if dir:
				dir.remove(file_name)
	
	items.remove_at(index)

func remove_by_session_id(session_id: String) -> void:
	"""Remove session by its ID"""
	for i in range(items.size()):
		var session: Session = items[i].get("session")
		if session and session.session_id == session_id:
			remove_at(i)
			return

func remove_all() -> void:
	var dir := DirAccess.open(sessions_directory)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(FILE_EXTENSION):
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	items.clear()

func get_sessions() -> Array:
	"""Returns all session dictionaries: [{"session": Session, "file_name": String}]"""
	return items.duplicate()

func get_session_by_id(session_id: String) -> Session:
	"""Find a session by its ID"""
	for item in items:
		var session: Session = item.get("session")
		if session and session.session_id == session_id:
			return session
	return null

func get_sessions_for_program(program_name: String) -> Array:
	"""Returns all sessions for a specific program by name"""
	var filtered: Array = []
	var search_name := program_name.strip_edges()
	
	for item in items:
		var session: Session = item.get("session")
		if session and session.program and session.program.program_name == search_name:
			filtered.append(item)
	
	return filtered

func get_sessions_for_date(date_str: String) -> Array:
	"""Returns all sessions for a specific date (ISO format: YYYY-MM-DD)"""
	var filtered: Array = []
	
	for item in items:
		var session: Session = item.get("session")
		if session and session.date == date_str:
			filtered.append(item)
	
	return filtered

func get_recent_sessions(limit: int = 10) -> Array:
	"""Returns the most recent N sessions"""
	var recent: Array = []
	var count := 0
	
	for item in items:
		if count >= limit:
			break
		recent.append(item)
		count += 1
	
	return recent

func create_session(program: Program, date: String, duration: int = 0, session_id: String = "") -> Session:
	"""Convenience method to create a new session"""
	var session := Session.new()
	session.program = program
	session.date = date
	session.duration = duration
	session.session_id = session_id if session_id != "" else _generate_session_id()
	return session

func _generate_session_id() -> String:
	"""Generate a unique session ID"""
	var timestamp = Time.get_unix_time_from_system()
	var random = randi() % 10000
	return "session_%d_%d" % [timestamp, random]

func update_session(session: Session) -> void:
	"""Find and update an existing session in the manager"""
	for i in range(items.size()):
		var item = items[i]
		var stored_session: Session = item.get("session")
		if stored_session == session or stored_session.session_id == session.session_id:
			# Remove old file
			var old_file_name = item.get("file_name", "")
			if old_file_name != "":
				var full_path = sessions_directory + old_file_name
				if FileAccess.file_exists(full_path):
					var dir := DirAccess.open(sessions_directory)
					if dir:
						dir.remove(old_file_name)
			
			# Save with new file
			var new_file_name := save_session_file(session)
			items[i] = {"session": session, "file_name": new_file_name}
			
			# Resort
			items.sort_custom(func(a, b):
				var a_session: Session = a["session"]
				var b_session: Session = b["session"]
				if a_session.date != b_session.date:
					return a_session.date > b_session.date
				return a["file_name"] < b["file_name"]
			)
			return
	
	push_error("SessionManager: Session not found in manager")

func get_session_objects() -> Array[Session]:
	"""Returns all Session objects directly"""
	var sessions: Array[Session] = []
	for item in items:
		var session: Session = item.get("session")
		if session:
			sessions.append(session)
	return sessions

func print_sessions(entry_manager) -> void:
	if items.is_empty():
		print("SessionManager: no sessions stored.")
		return
	
	print("SessionManager: %d session(s)" % items.size())
	for item in items:
		var session = item["session"]
		var program_name = session.program.program_name if session.program else "No Program"
		print("ID: %s - Date: %s - Program: %s - Duration: %dm" % [
			session.session_id,
			session.date,
			program_name,
			session.duration
		])
		
		# Get entries for this session
		var entries = entry_manager.get_entries_by_session(session.session_id)
		for entry in entries:
			var exercise_name = entry.exercise.name if entry.exercise else "Unknown"
			var sets_str = ""
			for set_data in entry.sets:
				sets_str += "[%dkg x %d] " % [set_data["weight"], set_data["reps"]]
			print("  - %s: %s" % [exercise_name, sets_str.strip_edges()])

func seed_example_data(exercise_manager, entry_manager, program_manager) -> void:
	"""Creates example session data for testing"""
	remove_all()
	
	# Get some exercises and a program
	var exercises = exercise_manager.get_all_exercise_objects()
	if exercises.is_empty():
		print("SessionManager: No exercises available to seed data")
		return
	
	var programs = program_manager.get_programs()
	if programs.is_empty():
		print("SessionManager: No programs available to seed data")
		return
	
	var program = programs[0].get("program") if programs else null
	if not program:
		print("SessionManager: Failed to get a program for seeding")
		return
	
	# Create a few sessions with example data
	var dates = ["2026-01-15", "2026-01-17", "2026-01-20", "2026-01-22"]
	var durations = [45, 60, 50, 55]
	
	for i in range(4):
		var session = create_session(program, dates[i], durations[i])
		
		# Create entries for this session
		var num_entries = randi_range(3, 5)
		for j in range(num_entries):
			var exercise = exercises[j % exercises.size()]
			
			# Create entry with 3-4 sets
			var sets_data = []
			var num_sets = randi_range(3, 4)
			for k in range(num_sets):
				var weight = 20.0 + (k * 5.0) + (randi() % 10)
				var reps = 8 + randi_range(0, 4)
				sets_data.append({"weight": weight, "reps": reps})
			
			var entry = entry_manager.create_entry(exercise, session.session_id, sets_data)
			entry_manager.add(entry)
		
		add(session)
	
	print("SessionManager: Seeded %d example sessions" % items.size())
