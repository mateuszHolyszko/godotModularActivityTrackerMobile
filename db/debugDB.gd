extends Node
class_name DebugDB

func _ready() -> void:
	print("--- DebugDB start ---")
	#test_add_measurement()
	#DataManager.MeasurementManager.remove_all()
	#DataManager.MeasurementManager.seed_example_data()
	#DataManager.MeasurementManager.print_measurements()
	#print(  DataManager.MeasurementManager.get_last_measurements()  )
	#print(  DataManager.MeasurementManager.get_last_measurement( "weight" )  )
	#print(  DataManager.MeasurementManager.query_measurement_by_weeks("weight", 4)  )
	print("--- DebugDB end ---")

func test_add_measurement() -> void:
	var m := Measurement.new()
	m.timestamp = Time.get_unix_time_from_system()
	m.arms = 32.5
	m.chest = 98.0
	m.waist = 80.0
	m.thigh = 55.0
	m.weight = 74.2
	DataManager.MeasurementManager.add(m)
	print("DebugDB: added test measurement")
