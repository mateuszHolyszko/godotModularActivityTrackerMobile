extends Panel

var session_entry_resource: Session
var _initialized: bool = false

@onready var date_label: Label = %DateLabel
@onready var program_label: Label = %ProgramLabel
@onready var duration_label: Label = %DurationLabel
@onready var bodyweight_label: Label = %BodyweightLabel

@onready var open_popup_button: Button = %OpenPopupButton
@onready var popup_panel: Popup_panel = %PopUpPanel

func set_data(entry: Session):
	session_entry_resource = entry
	if _initialized:
		update_labels()

func _ready():
	open_popup_button.pressed.connect( on_open_popup_button_pressed )
	
	_initialized = true
	update_labels()

func update_labels():
	if session_entry_resource == null:
		return
	
	# Program label with ORPHAN fallback
	if session_entry_resource.program and session_entry_resource.program.program_name != "":
		program_label.text = session_entry_resource.program.program_name
		program_label.modulate = Color.WHITE  # Reset to default color
	else:
		program_label.text = "ORPHAN"
		program_label.modulate = Color.RED
	
	duration_label.text = "%d min" % session_entry_resource.duration
	bodyweight_label.text = "%.2f kg" % session_entry_resource.body_weight
	
	# Format date from YYYY-MM-DD to DD-MM-YYYY
	var date_str = session_entry_resource.date
	var parts = date_str.split("-")
	if parts.size() == 3:
		date_label.text = "%s-%s-%s" % [parts[2], parts[1], parts[0]]
	else:
		date_label.text = date_str  # fallback

func on_open_popup_button_pressed():
	popup_panel.open()
