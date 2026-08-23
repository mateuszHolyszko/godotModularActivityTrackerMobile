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
