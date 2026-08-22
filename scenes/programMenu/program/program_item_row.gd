# programItemRow.gd
extends Control

# Signal definitions
signal item_modified(index: int)
signal item_deleted(index: int)
signal item_selected(index: int, exercise_name: String)

# Export variables
@export var item_index: int = -1
@export var item_type: String = "exercise"  # "exercise" or "superset"
@export var exercise_name: String = ""
@export var program_resource: Program = null  # This should be the working copy
@export var parent_menu: Menu
@export var sub_menu_container: Control

# Node references
@onready var order_label: Label = %OrderLabel
@onready var up_order_button: Button = %UpButton
@onready var down_order_button: Button = %DownButton
@onready var item_button: PickExerciseButton = %Item
@onready var delete_button: Button = %DeleteButton
@onready var target_color_indicator: ColorRect = %TargetColorIndicator

func _ready():
	# Set up the item display
	_update_display()
	
	# Set the current value of the picker
	item_button.current_value = exercise_name
	
	# Connect signals
	item_button.value_changed.connect(_on_item_value_changed)
	up_order_button.pressed.connect(_on_move_up_pressed)
	down_order_button.pressed.connect(_on_move_down_pressed)
	delete_button.pressed.connect(_on_delete_button_pressed)
	
	# Set up the submenu container for the picker
	item_button.submenu_container_path = sub_menu_container.get_path()
	
	# Update color based on exercise target
	_update_color()

func _update_display() -> void:
	"""
	Update the display based on the current state.
	"""
	# Update order label (show 1-based index)
	if item_index >= 0:
		order_label.text = "%d" % (item_index + 1)
	
	# Update the picker text based on item type
	if item_type == "exercise":
		if exercise_name and not exercise_name.is_empty():
			item_button.current_value = exercise_name
		else:
			item_button.current_value = null
	else:
		# For superset, show a special label
		item_button.current_value = "Superset (to be implemented)"
	
	# Enable/disable move buttons based on position
	up_order_button.disabled = (item_index <= 0)
	down_order_button.disabled = (item_index >= _get_item_count() - 1)

func _get_item_count() -> int:
	"""
	Get the total number of items in the program.
	"""
	if not program_resource:
		return 0
	return program_resource.items.size()

func _update_color() -> void:
	"""
	Update the color rect based on the exercise's target muscle.
	"""
	if not target_color_indicator:
		return
	
	# Only update color for exercise items
	if item_type != "exercise":
		# For supersets, use a neutral color
		if target_color_indicator.has_method("clear_color"):
			target_color_indicator.clear_color()
		else:
			target_color_indicator.color = Color.WHITE
		return
	
	# Update the color rect with the exercise name
	if target_color_indicator.has_method("set_exercise"):
		target_color_indicator.set_exercise(exercise_name)
	else:
		# Fallback if color_rect doesn't have the script attached
		if exercise_name.is_empty():
			target_color_indicator.color = Color.GRAY
			return
		
		var target_muscle = DataManager.ExerciseManager.get_exercise_target_muscle(exercise_name)
		if target_muscle.is_empty():
			target_color_indicator.color = Color.GRAY
			return
		
		var muscle_color = MuscleDict.get_color(target_muscle)
		target_color_indicator.color = muscle_color if muscle_color else Color.GRAY

func _notify_parent_of_change() -> void:
	"""
	Notify the parent menu that a change was made.
	This allows the parent to mark unsaved changes.
	"""
	if parent_menu and parent_menu.has_method("_mark_unsaved_changes"):
		parent_menu._mark_unsaved_changes()

func _on_item_value_changed(new_value) -> void:
	"""
	Handle when the exercise selection changes.
	"""
	if not program_resource:
		push_error("No program resource available")
		return
	
	if item_index < 0 or item_index >= program_resource.items.size():
		push_error("Invalid item index: %d" % item_index)
		return
	
	var item = program_resource.items[item_index]
	
	if item_type == "exercise":
		# Update the exercise name in the program
		var new_exercise_name = str(new_value).strip_edges()
		if new_exercise_name.is_empty():
			# If empty, revert to previous value or set to null
			item_button.current_value = exercise_name
			return
		
		# Update the item
		item["exercise_name"] = new_exercise_name
		exercise_name = new_exercise_name
		
		# Update the color based on new exercise
		_update_color()
		
		# Notify parent of change
		_notify_parent_of_change()
		
		# Emit signal that the item was modified
		item_modified.emit(item_index)
		
		print("Exercise updated to: %s" % new_exercise_name)
	else:
		push_error("Cannot change value for item type: %s" % item_type)

func _on_move_up_pressed() -> void:
	"""
	Move this item up in the list.
	"""
	if not program_resource:
		return
	
	var item_count = _get_item_count()
	if item_index <= 0 or item_index >= item_count:
		return
	
	# Swap with the item above in the program resource
	var temp = program_resource.items[item_index]
	program_resource.items[item_index] = program_resource.items[item_index - 1]
	program_resource.items[item_index - 1] = temp
	
	# Update the local index
	var old_index = item_index
	item_index -= 1
	
	# Notify parent of change
	_notify_parent_of_change()
	
	# Emit signal that the item was modified
	item_modified.emit(item_index)
	
	# Update display
	_update_display()
	
	print("Item moved up from %d to %d" % [old_index, item_index])

func _on_move_down_pressed() -> void:
	"""
	Move this item down in the list.
	"""
	if not program_resource:
		return
	
	var item_count = _get_item_count()
	if item_index < 0 or item_index >= item_count - 1:
		return
	
	# Swap with the item below in the program resource
	var temp = program_resource.items[item_index]
	program_resource.items[item_index] = program_resource.items[item_index + 1]
	program_resource.items[item_index + 1] = temp
	
	# Update the local index
	var old_index = item_index
	item_index += 1
	
	# Notify parent of change
	_notify_parent_of_change()
	
	# Emit signal that the item was modified
	item_modified.emit(item_index)
	
	# Update display
	_update_display()
	
	print("Item moved down from %d to %d" % [old_index, item_index])

func _on_delete_button_pressed() -> void:
	"""
	Delete this item from the program with confirmation.
	"""
	if not program_resource:
		push_error("No program resource available")
		return
	
	if item_index < 0 or item_index >= program_resource.items.size():
		push_error("Invalid item index: %d" % item_index)
		return
	
	# Check if parent_menu has confirm_dialog
	if not parent_menu:
		push_error("Parent menu not set")
		return
	
	# Get the confirm dialog from parent menu
	var confirm_dialog = parent_menu.get("confirm_dialog")
	if not confirm_dialog:
		push_error("Confirm dialog not found in parent menu")
		return
	
	# Create confirmation message
	var item_name = exercise_name if not exercise_name.is_empty() else "Item %d" % (item_index + 1)
	var confirm_message = "Delete exercise '%s' from the program?" % item_name
	
	# Request confirmation
	confirm_dialog.request_confirmation(
		confirm_message,
		_on_delete_confirmed
	)

func _on_delete_confirmed() -> void:
	"""
	Handle the confirmed deletion of the item.
	"""
	if not program_resource:
		push_error("No program resource available")
		return
	
	if item_index < 0 or item_index >= program_resource.items.size():
		push_error("Invalid item index: %d" % item_index)
		return
	
	# Remove the item from the program
	program_resource.items.remove_at(item_index)
	
	# Notify parent of change
	_notify_parent_of_change()
	
	# Emit signal that the item was deleted
	item_deleted.emit(item_index)
	
	# Remove this row
	queue_free()
	
	print("Item %d deleted" % item_index)

# Optional: Handle cancellation if you want to do something specific
func _on_delete_cancelled() -> void:
	print("Delete cancelled for item %d: %s" % [item_index, exercise_name])

# Public methods for external control

func set_item_data(index: int, type: String, name: String, resource: Program) -> void:
	"""
	Set or update the item data.
	"""
	item_index = index
	item_type = type
	exercise_name = name
	program_resource = resource
	
	# Update the picker's current value
	if type == "exercise":
		item_button.current_value = name
	else:
		item_button.current_value = "Superset"
	
	_update_display()
	_update_color()

func update_order_label(new_index: int) -> void:
	"""
	Update the order label when items are reordered.
	"""
	item_index = new_index
	_update_display()

func refresh_display() -> void:
	"""
	Refresh the display without changing data.
	"""
	_update_display()
	_update_color()

func get_item_data() -> Dictionary:
	"""
	Get the current item data.
	"""
	return {
		"index": item_index,
		"type": item_type,
		"name": exercise_name,
		"program": program_resource
	}

# Optional: Method to handle superset selection (for future implementation)
func set_superset_data(exercise_names: Array) -> void:
	"""
	Set the item as a superset with the given exercise names.
	"""
	item_type = "superset"
	# For now, just display as a special label
	item_button.current_value = "Superset: %s" % ", ".join(exercise_names)
	_update_display()
	# For supersets, use a neutral color
	if target_color_indicator and target_color_indicator.has_method("clear_color"):
		target_color_indicator.clear_color()
	elif target_color_indicator:
		target_color_indicator.color = Color.WHITE

# Clean up when the row is removed
func _exit_tree() -> void:
	# Disconnect signals to avoid memory leaks
	if item_button and item_button.value_changed.is_connected(_on_item_value_changed):
		item_button.value_changed.disconnect(_on_item_value_changed)
	
	if up_order_button and up_order_button.pressed.is_connected(_on_move_up_pressed):
		up_order_button.pressed.disconnect(_on_move_up_pressed)
	
	if down_order_button and down_order_button.pressed.is_connected(_on_move_down_pressed):
		down_order_button.pressed.disconnect(_on_move_down_pressed)
	
	if delete_button and delete_button.pressed.is_connected(_on_delete_button_pressed):
		delete_button.pressed.disconnect(_on_delete_button_pressed)
