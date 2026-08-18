extends Node

@onready var timeLabel: Label = %TimeLabel
@onready var dateLabel: Label = %DateLabel
@onready var dateTimeTimer: Timer = %DateTimeTimer


func _ready():
	update_datetime()
	dateTimeTimer.timeout.connect(update_datetime)


func update_datetime():
	var current_time = Time.get_datetime_dict_from_system()

	timeLabel.text = "%02d:%02d" % [
		current_time.hour,
		current_time.minute
	]

	dateLabel.text = "%02d-%02d\n%04d" % [
		current_time.day,
		current_time.month,
		current_time.year
	]
