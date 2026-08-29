extends Panel

var mesurement_entry_resource: MeasurementEntry
var _initialized: bool = false

@onready var date_label: Label = %DateLabel
@onready var type_label: Label = %TypeLabel
@onready var value_label: Label = %ValueLabel

func set_data(entry: MeasurementEntry):
	mesurement_entry_resource = entry
	if _initialized:
		update_labels()

func _ready():
	_initialized = true
	update_labels()

func update_labels():
	if mesurement_entry_resource == null:
		return
	
	type_label.text = mesurement_entry_resource.type
	value_label.text = "%.2f" % mesurement_entry_resource.value
	
	var timestamp = mesurement_entry_resource.timestamp
	if timestamp > 0:
		var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
		date_label.text = "%d-%d-%d " % [
			datetime.day,
			datetime.month,
			datetime.year
		]
