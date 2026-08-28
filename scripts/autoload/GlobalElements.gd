# GlobalElements.gd
# Add this as an autoload in Project Settings > Autoload

extends Node

# Registered elements
var TransitionRect: ColorRect = null
var CurrentWorkout: WorkoutSession = null
var LoadingScreen: LoadingPanel = null

# Signal for workout changes (emits the new workout or null)
signal CurrentWorkoutChanged(workout: WorkoutSession)

# Simple setter
func set_current_workout(workout: WorkoutSession) -> void:
	CurrentWorkout = workout
	#print("EMITEDDDDDD")
	CurrentWorkoutChanged.emit(workout)

# Simple nuller
func null_current_workout() -> void:
	CurrentWorkout = null
	#print("EMITEDDDDDD")
	CurrentWorkoutChanged.emit(null)
