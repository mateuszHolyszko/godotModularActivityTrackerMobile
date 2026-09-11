extends Menu

@onready var _sub_menu_container: Container = %SubMenuContainer
@onready var confirm_menu: ConfirmationEntryMenu = %ConfirmationEntryMenu

@onready var mesurment_button: Button = %MesurmentButton
@onready var exercise_entry_button: Button = %ExerciseEntryButton
@onready var session_button: Button = %SessionButton

@onready var input_date_from: DateInputButton = %DateFromInputButton
@onready var input_date_to: DateInputButton = %DateToInputButton

@onready var data_panel: Panel = %DataPanel # holds one of following scenes
var mesurement_data: PackedScene = null
var exercise_entry_data: PackedScene = null
var session_data: PackedScene = null

@onready var batch_size_label: Label = %BatchSizeLabel # displays number of data points in current_data_instance, format: "Batch size:\n{value}"
@onready var batch_delete_button: Button = %BatchDeleteButton

@onready var import_button: Button = %ImportDataButton
@onready var export_button: Button = %ExportDataButton

# Keep reference to the current instance so we can manage it
var current_data_instance: Node = null

func _ready():
	# Load scenes
	mesurement_data = load("res://scenes/dataMenu/mesurment/mesurement_data.tscn")
	exercise_entry_data = load("res://scenes/dataMenu/exerciseEntry/exercise_entry_data.tscn")
	session_data = load("res://scenes/dataMenu/session/session_data.tscn")
	
	mesurment_button.pressed.connect(_on_mesurment_pressed)
	exercise_entry_button.pressed.connect(_on_exercise_entry_pressed)
	session_button.pressed.connect(_on_session_button_pressed)
	
	# Connect date buttons
	input_date_from.date_confirmed.connect(_on_date_from_confirmed)
	input_date_to.date_confirmed.connect(_on_date_to_confirmed)
	batch_delete_button.pressed.connect(_on_batch_delete_pressed)
	
	export_button.pressed.connect(_on_export_pressed)
	import_button.pressed.connect(_on_import_pressed)

func _on_mesurment_pressed() -> void:
	exercise_entry_button.disabled = false
	session_button.disabled = false
	
	mesurment_button.disabled = true
	_clear_data_panel()
	_add_scene_to_panel(mesurement_data)
	
	# Update the newly added panel with current date range
	_update_current_panel_dates()

func _on_exercise_entry_pressed() -> void:
	session_button.disabled = false
	mesurment_button.disabled = false
	
	exercise_entry_button.disabled = true
	_clear_data_panel()
	_add_scene_to_panel(exercise_entry_data)
	
	# Update the newly added panel with current date range
	_update_current_panel_dates()

func _on_session_button_pressed() -> void:
	exercise_entry_button.disabled = false
	mesurment_button.disabled = false
	
	session_button.disabled = true
	_clear_data_panel()
	_add_scene_to_panel(session_data)
	
	# Update the newly added panel with current date range
	_update_current_panel_dates()

func _on_batch_delete_pressed() -> void:
	if current_data_instance == null:
		return
	if not current_data_instance.has_method("get_data_points"):
		return
	
	var datapoints: Array = current_data_instance.get_data_points()
	if datapoints.is_empty():
		return
	
	var count := datapoints.size()
	var prompt := "Delete %d datapoint%s?" % [count, "" if count == 1 else "s"]
	if confirm_menu:
		confirm_menu.request_confirmation(prompt, _on_batch_delete_confirmed)
	else:
		push_error("DataMenu: Confirm dialog is not available for batch delete")

func _on_batch_delete_confirmed() -> void:
	if current_data_instance == null:
		return
	if not current_data_instance.has_method("get_data_points"):
		return
	
	var datapoints: Array = current_data_instance.get_data_points()
	if datapoints.is_empty():
		return
	
	for item in datapoints:
		if item is MeasurementEntry:
			_delete_measurement_entry(item)
		elif item is Dictionary:
			if item.has("entry") and item["entry"] is ExerciseEntry:
				_delete_exercise_entry(item["entry"])
			elif item.has("session") and item["session"] is Session:
				_delete_session(item["session"])
		elif item is ExerciseEntry:
			_delete_exercise_entry(item)
		elif item is Session:
			_delete_session(item)
	
	if current_data_instance.has_method("refresh_data"):
		current_data_instance.refresh_data()

func _delete_measurement_entry(entry: MeasurementEntry) -> void:
	for i in range(DataManager.MeasurementManager.items.size() - 1, -1, -1):
		if DataManager.MeasurementManager.items[i] == entry:
			DataManager.MeasurementManager.remove_at(i)
			return

func _delete_exercise_entry(entry: ExerciseEntry) -> void:
	for i in range(DataManager.ExerciseEntryManager.items.size() - 1, -1, -1):
		var item = DataManager.ExerciseEntryManager.items[i]
		var stored_entry: ExerciseEntry = item.get("entry")
		if stored_entry == entry:
			DataManager.ExerciseEntryManager.remove_at(i)
			return

func _delete_session(session: Session) -> void:
	DataManager.ExerciseEntryManager.remove_by_session_id(session.session_id)
	for i in range(DataManager.SessionManager.items.size() - 1, -1, -1):
		var item = DataManager.SessionManager.items[i]
		var stored_session: Session = item.get("session")
		if stored_session == session or stored_session.session_id == session.session_id:
			DataManager.SessionManager.remove_at(i)
			return

func _on_date_from_confirmed(new_date: Dictionary) -> void:
	# Convert date dictionary to Unix timestamp
	var from_timestamp = Time.get_unix_time_from_datetime_dict(new_date)
	
	# Update the current data panel's from_time
	current_data_instance.from_time = from_timestamp

func _on_date_to_confirmed(new_date: Dictionary) -> void:
	# Convert date dictionary to Unix timestamp
	var to_timestamp = Time.get_unix_time_from_datetime_dict(new_date)
	
	current_data_instance.to_time = to_timestamp

func _update_current_panel_dates() -> void:
	if current_data_instance == null:
		return
	
	# Get timestamps from date buttons
	var from_date = input_date_from.get_current_date()
	var to_date = input_date_to.get_current_date()
	
	var from_timestamp = Time.get_unix_time_from_datetime_dict(from_date)
	var to_timestamp = Time.get_unix_time_from_datetime_dict(to_date)
	
	# Update the panel's dates
	current_data_instance.from_time = from_timestamp
	current_data_instance.to_time = to_timestamp

func _on_data_loaded(count: int) -> void:
	batch_size_label.text = "Batch size\n" + str(count)

func _clear_data_panel() -> void:
	# Remove all children from data_panel
	for child in data_panel.get_children():
		child.queue_free()
	current_data_instance = null

func _add_scene_to_panel(scene: PackedScene) -> void:
	if scene == null:
		return
	
	# Instantiate the scene
	var instance = scene.instantiate()
	
	# Pass sub menu to it
	instance.sub_menu_container = _sub_menu_container
	
	# Add it as a child of data_panel
	data_panel.add_child(instance)
	
	# Store reference
	current_data_instance = instance
	
	# Connect the data_loaded signal if the instance has it
	if instance.has_signal("data_loaded"):
		instance.data_loaded.connect(_on_data_loaded)

func _on_export_pressed() -> void:
	confirm_menu.request_confirmation("Are you sure?", _on_export_confirmed)

func _on_export_confirmed() -> void:
	var filters = PackedStringArray(["*/*"])
	var current_directory = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	
	# Build the filename with the current date
	var now = Time.get_datetime_dict_from_system()
	var date_string = "%02d_%02d_%04d" % [now.day, now.month, now.year]
	var file_name = "MAT_export_%s.json" % date_string
	
	DisplayServer.file_dialog_show(
		"Export Data",
		current_directory,
		file_name,       # Default filename: MAT_export_dd_mm_yyyy.json
		false,           # show_hidden
		DisplayServer.FILE_DIALOG_MODE_SAVE_FILE,
		filters,
		_on_file_picker_result
	)

func _on_file_picker_result(status: bool, selected_paths: PackedStringArray, _filter_index: int) -> void:
	if not status or selected_paths.is_empty():
		return
	
	var uri = selected_paths[0]
	
	# Write directly to the content:// URI
	var file = FileAccess.open(uri, FileAccess.WRITE)
	if file:
		var json_data = JSON.stringify(DataManager.export_all_data(), "\t")
		file.store_string(json_data)
		file.close()
		print("Export successful")
	else:
		print("Failed to open: ", uri, " Error: ", FileAccess.get_open_error())

func _on_import_pressed() -> void:
	confirm_menu.request_confirmation("Are you want to import data?\nTHIS WILL RESULT IN\nDELITION OF EXISTING\nDATA", _on_import_confirmed)

func _on_import_confirmed() -> void:
	var filters = PackedStringArray(["*.json"])
	var current_directory = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	
	DisplayServer.file_dialog_show(
		"Import Data",
		current_directory,
		"",              # No default filename for loading
		false,           # show_hidden
		DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,   # <-- OPEN, not SAVE
		filters,
		_on_import_file_picker_result
	)

func _on_import_file_picker_result(status: bool, selected_paths: PackedStringArray, _filter_index: int) -> void:
	if not status or selected_paths.is_empty():
		return
	
	var uri = selected_paths[0]
	
	# 1. Read the file
	var file = FileAccess.open(uri, FileAccess.READ)
	if file == null:
		push_error("Failed to open import file: %s (error %d)" % [uri, FileAccess.get_open_error()])
		return
	var text = file.get_as_text()
	file.close()
	
	# 2. Parse JSON
	var parsed = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		push_error("Import file is not a valid JSON object.")
		return
	
	# 3. Wipe existing data and load the new one
	var isSuccess := DataManager.import_all_data(parsed)
	if isSuccess: 
		NotificationManager.success("Data imported successfully")
		# Refresh datapoints in current panel
		current_data_instance.refresh_data()
	else: NotificationManager.error("Import failed")


func recalculate_batch_size() -> void:
	if current_data_instance == null:
		return
	if not current_data_instance.has_method("get_data_points"):
		return
	var datapoints: Array = current_data_instance.get_data_points()
	_on_data_loaded(datapoints.size())
