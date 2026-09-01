extends Panel
class_name Popup_panel

@onready var delete_button: Button = %DeleteButton
@onready var close_popup_button: Button = %ClosePopUp

# Reference to the resource/item to delete (found by traversing tree)
var target_resource: Variant = null
var parent_data_panel: Node = null

func _ready():
	delete_button.pressed.connect(_on_delete_pressed)
	close_popup_button.pressed.connect(_on_close_pressed)
	
	parent_data_panel = get_parent()
	
	# Initially hide the popup
	hide()

func _on_close_pressed() -> void:
	hide()

func _on_delete_pressed() -> void:
	# Find the target resource from the parent tree
	_find_target_resource()
	
	if target_resource == null:
		push_error("DeletePopup: No target resource found")
		hide()
		return
	
	# Delete the item from DataManager
	if target_resource is MeasurementEntry:
		_delete_measurement_entry(target_resource)
	elif target_resource is ExerciseEntry:
		_delete_exercise_entry(target_resource)
	elif target_resource is Session:
		_delete_session(target_resource)
	elif target_resource is Dictionary:
		if target_resource.has("entry") and target_resource["entry"] is ExerciseEntry:
			_delete_exercise_entry(target_resource["entry"])
		elif target_resource.has("session") and target_resource["session"] is Session:
			_delete_session(target_resource["session"])
	
	# Delete the parent node (the entry resource panel)
	# This will automatically delete this popup as well
	if parent_data_panel:
		parent_data_panel.queue_free()
	
	# Clear references (though they won't be needed after parent deletion)
	target_resource = null
	parent_data_panel = null

func _find_target_resource() -> void:
	# Check if the node has a property that holds the resource
	if "mesurement_entry_resource" in parent_data_panel and parent_data_panel.mesurement_entry_resource != null:
		target_resource = parent_data_panel.mesurement_entry_resource
		return
	elif "exercise_entry_resource" in parent_data_panel and parent_data_panel.exercise_entry_resource != null:
		target_resource = parent_data_panel.exercise_entry_resource
		return
	elif "session_entry_resource" in parent_data_panel and parent_data_panel.session_entry_resource != null:
		target_resource = parent_data_panel.session_entry_resource
		return

func open() -> void:
	show()
	_find_target_resource()

# Delete methods
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
