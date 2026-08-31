extends Panel

var exercise_entry_resource: ExerciseEntry
var _initialized: bool = false

@onready var date_label: Label = %DateLabel
@onready var session_program_label: Label = %SessionIdLabel
@onready var exercise_label: Label = %ExerciseLabel
@onready var number_of_sets_label: Label = %NumberOfSetsLabel

func set_data(entry: ExerciseEntry):
	exercise_entry_resource = entry
	if _initialized:
		update_labels()

func _ready():
	_initialized = true
	update_labels()

func update_labels():
	if exercise_entry_resource == null:
		return
	
	var program = DataManager.SessionManager.get_session_by_id(exercise_entry_resource.session_id).program
	if program:
		session_program_label.text =  program.program_name
	else:
		session_program_label.text = "ORPHAN"
		session_program_label.modulate = Color.RED
	
	# Exercise label with ORPHAN fallback
	if exercise_entry_resource.exercise and exercise_entry_resource.exercise.name != "":
		exercise_label.text = exercise_entry_resource.exercise.name
		exercise_label.modulate = Color.WHITE  # Reset to default color
	else:
		exercise_label.text = "ORPHAN"
		exercise_label.modulate = Color.RED
	
	number_of_sets_label.text = str(exercise_entry_resource.sets.size())
	
	# ExerciseEntry has no date/timestamp get it via session
	var date_str := DataManager.SessionManager.get_session_by_id( exercise_entry_resource.session_id ).date
	# Format date from YYYY-MM-DD to DD-MM-YYYY
	var parts = date_str.split("-")
	if parts.size() == 3:
		date_label.text = "%s-%s-%s" % [parts[2], parts[1], parts[0]]
	else:
		date_label.text = date_str  # fallback
