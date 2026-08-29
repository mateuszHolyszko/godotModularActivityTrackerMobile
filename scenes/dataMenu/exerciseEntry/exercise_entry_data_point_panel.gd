extends Panel

var mesurement_entry_resource: ExerciseEntry
var _initialized: bool = false

@onready var date_label: Label = %DateLabel
@onready var session_id_label: Label = %SessionIdLabel
@onready var exercise_label: Label = %ExerciseLabel
@onready var number_of_sets_label: Label = %NumberOfSetsLabel

func set_data(entry: ExerciseEntry):
	mesurement_entry_resource = entry
	if _initialized:
		update_labels()

func _ready():
	_initialized = true
	update_labels()

func update_labels():
	if mesurement_entry_resource == null:
		return
	
	session_id_label.text = mesurement_entry_resource.session_id.right(12)
	exercise_label.text = mesurement_entry_resource.exercise.name if mesurement_entry_resource.exercise else ""
	number_of_sets_label.text = str(mesurement_entry_resource.sets.size())
	
	# ExerciseEntry has no date/timestamp get it via session
	date_label.text = ""
