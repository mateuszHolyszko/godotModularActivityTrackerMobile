extends Node
const BASE_DIR := "user://db/data/"

var MeasurementManager := preload("res://db/mesurments/measurement_manager.gd").new()
var ExerciseManager := preload("res://db/exercises/exercise_manager.gd").new()
var ProgramManager := preload("res://db/programs/program_manager.gd").new()
var ExerciseEntryManager := preload("res://db/exercise entry/exercise_entry_manager.gd").new()
var SessionManager := preload("res://db/session/session_manager.gd").new()

func _ready() -> void:
	_ensure_dir()
	MeasurementManager.setup(BASE_DIR)
	ExerciseManager.setup(BASE_DIR)
	ProgramManager.setup(BASE_DIR)
	ExerciseEntryManager.setup(BASE_DIR)
	SessionManager.setup(BASE_DIR)

	# Load in proper order
	MeasurementManager.load()
	ExerciseManager.load()
	ProgramManager.load()
	ExerciseEntryManager.load(ExerciseManager)
	SessionManager.load(ExerciseManager, ExerciseEntryManager, ProgramManager)

func _ensure_dir() -> void:
	if not DirAccess.dir_exists_absolute(BASE_DIR):
		DirAccess.make_dir_recursive_absolute(BASE_DIR)

func export_all_data() -> Dictionary:
	return {
		"measurements": MeasurementManager.get_all_serialized(),
		"exercises": ExerciseManager.get_all_serialized(),
		"programs": ProgramManager.get_all_serialized(),
		"exercise_entries": ExerciseEntryManager.get_all_serialized(),
		"sessions": SessionManager.get_all_serialized()
	}

func import_all_data(data: Dictionary) -> bool:
	if not _validate_import_data(data):
		return false

	# Delete existing persisted data and clear memory.
	SessionManager.remove_all()
	ExerciseEntryManager.remove_all()
	ProgramManager.remove_all()
	ExerciseManager.remove_all()
	MeasurementManager.remove_all()

	# Rebuild and persist measurements.
	for raw_data in data.get("measurements", []):
		var entry := MeasurementEntry.from_dict(raw_data)
		if entry:
			MeasurementManager.items.append(entry)
			MeasurementManager.save_entry_file(entry)

	# Rebuild and persist exercises.
	for raw_data in data.get("exercises", []):
		var exercise := Exercise.from_dict(raw_data)
		if exercise:
			ExerciseManager.add(exercise)

	# Rebuild and persist programs.
	for raw_data in data.get("programs", []):
		var program := Program.from_dict(raw_data)
		if program:
			ProgramManager.add(program)

	# Rebuild entries after exercises exist.
	for raw_data in data.get("exercise_entries", []):
		var entry := ExerciseEntry.from_dict(raw_data, ExerciseManager)
		if entry:
			ExerciseEntryManager.add(entry)

	# Rebuild sessions after programs exist.
	for raw_data in data.get("sessions", []):
		var session := Session.from_dict(raw_data, ProgramManager)
		if session:
			SessionManager.add(session)

	return true

func _validate_import_data(data: Dictionary) -> bool:
	var sections := ["measurements", "exercises", "programs", "exercise_entries", "sessions"]
	for section in sections:
		if not data.has(section):
			push_error("Import data is missing section '%s'." % section)
			return false
		if not (data[section] is Array):
			push_error("Import section '%s' must be an array." % section)
			return false

	var exercise_names := {}
	for raw_data in data["exercises"]:
		if not (raw_data is Dictionary):
			return _invalid_import("Each exercise must be an object.")
		if not _require_string(raw_data, "name", "exercise"):
			return false
		var exercise_name = raw_data["name"].strip_edges()
		if exercise_name == "" or exercise_names.has(exercise_name.to_lower()):
			return _invalid_import("Exercise names must be non-empty and unique.")
		exercise_names[exercise_name.to_lower()] = true

	var program_names := {}
	for raw_data in data["programs"]:
		if not (raw_data is Dictionary):
			return _invalid_import("Each program must be an object.")
		if not _require_string(raw_data, "program_name", "program"):
			return false
		var program_name = raw_data["program_name"].strip_edges()
		if program_name == "" or program_names.has(program_name.to_lower()):
			return _invalid_import("Program names must be non-empty and unique.")
		program_names[program_name.to_lower()] = true
		if not _validate_program_items(raw_data.get("items", []), exercise_names):
			return false

	var session_ids := {}
	for raw_data in data["sessions"]:
		if not (raw_data is Dictionary):
			return _invalid_import("Each session must be an object.")
		if not _require_string(raw_data, "session_id", "session"):
			return false
		var session_id: String = raw_data["session_id"]
		if session_id == "" or session_ids.has(session_id):
			return _invalid_import("Session IDs must be non-empty and unique.")
		session_ids[session_id] = true
		if not _require_string(raw_data, "date", "session") or raw_data["date"] == "":
			return false
		var program_name: String = raw_data.get("program_name", "")
		if program_name != "" and not program_names.has(program_name.to_lower()):
			return _invalid_import("Session references unknown program '%s'." % program_name)

	for raw_data in data["exercise_entries"]:
		if not (raw_data is Dictionary):
			return _invalid_import("Each exercise entry must be an object.")
		var exercise_name: String = raw_data.get("exercise_name", "")
		if exercise_name != "" and not exercise_names.has(exercise_name.to_lower()):
			return _invalid_import("Exercise entry references unknown exercise '%s'." % exercise_name)
		var session_id: String = raw_data.get("session_id", "")
		if session_id != "" and not session_ids.has(session_id):
			return _invalid_import("Exercise entry references unknown session '%s'." % session_id)
		if not (raw_data.get("sets", []) is Array):
			return _invalid_import("Exercise entry sets must be an array.")

	for raw_data in data["measurements"]:
		if not (raw_data is Dictionary):
			return _invalid_import("Each measurement must be an object.")
		if not _require_string(raw_data, "type", "measurement"):
			return false
		if raw_data["type"].to_lower() not in MeasurementManager.VALID_TYPES:
			return _invalid_import("Unknown measurement type '%s'." % raw_data["type"])
		if not raw_data.has("value") or not raw_data.has("timestamp"):
			return _invalid_import("Measurements require value and timestamp.")

	return true

func _validate_program_items(items: Variant, exercise_names: Dictionary) -> bool:
	if not (items is Array):
		return _invalid_import("Program items must be an array.")
	for item in items:
		if not (item is Dictionary):
			return _invalid_import("Each program item must be an object.")
		var item_type: String = item.get("type", "")
		var names: Array = [item.get("exercise_name", "")] if item_type == "exercise" else item.get("exercise_names", []) if item_type == "superset" else []
		if item_type not in ["exercise", "superset"] or not (names is Array):
			return _invalid_import("Program contains an invalid item.")
		for exercise_name in names:
			if not (exercise_name is String) or exercise_name.strip_edges() == "" or not exercise_names.has(exercise_name.to_lower()):
				return _invalid_import("Program references an unknown exercise.")
	return true

func _require_string(data: Dictionary, key: String, kind: String) -> bool:
	if not data.has(key) or not (data[key] is String):
		push_error("Import %s requires string field '%s'." % [kind, key])
		return false
	return true

func _invalid_import(message: String) -> bool:
	push_error("Invalid import data: %s" % message)
	return false
