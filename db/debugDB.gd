extends Node
class_name DebugDB

func _ready() -> void:
	print("--- DebugDB start ---")
	### MESURMENTS
	#test_add_measurement()
	#DataManager.MeasurementManager.remove_all()
	#DataManager.MeasurementManager.seed_example_data()
	#DataManager.MeasurementManager.print_measurements()
	#print(  DataManager.MeasurementManager.get_last_measurements()  )
	#print(  DataManager.MeasurementManager.get_last_measurement( "weight" )  )
	#print(  DataManager.MeasurementManager.query_measurement_by_weeks("weight", 4)  )
	### EXERCISES
	#DataManager.ExerciseManager.seed_example_data()
	#DataManager.ExerciseManager.remove_all()
	#DataManager.ExerciseManager.add_exercise("ring pushup","Chest",true,6,12)
	#print(DataManager.ExerciseManager.get_exercise_objects_for_target("Chest")[0].name)
	#DataManager.ExerciseManager.print_exercises()
	### PROGRAMS
	#DataManager.ProgramManager.seed_example_programs()
	#DataManager.ProgramManager.print_all_programs()
	#DataManager.ProgramManager.print_program("Superset Circuit")
	### EXERCISE_ENTRY
	#DataManager.ExerciseEntryManager.seed_example_data( DataManager.ExerciseManager )  
	DataManager.ExerciseEntryManager.print_entries()
	### SESSIONS
	DataManager.SessionManager.print_sessions( DataManager.ExerciseEntryManager )
	print("--- DebugDB end ---")
