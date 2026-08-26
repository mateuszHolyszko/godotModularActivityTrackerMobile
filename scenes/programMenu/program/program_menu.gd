extends Menu

@export var program_resource: Program = null

@onready var program_label: Label = %ProgramNameLabel
@onready var back_button: Button = %BackButton
@onready var save_changes_button: Button = %SaveButton
@onready var items_container: VBoxContainer = %ScrollContent

@onready var insert_item_input: InsertPositionInput = %InsertPositionInput
@onready var insert_item_button: Button = %InsertPositionButton

@onready var sub_menu_container: Container = %SubMenuContainer
@onready var confirm_dialog: ConfirmationEntryMenu = %ConfirmationEntryMenu

# Signal to notify when the program changes
signal program_changed(new_program: Program)
# New signal for when the working program is modified
signal working_program_modified()

var _is_ready: bool = false
var _program_item_row_scene: PackedScene = null

# Working copy of the program - this is what we edit
var _working_program: Program = null
var _has_unsaved_changes: bool = false

func _ready():
	# Load the program item row scene once and cache it
	_program_item_row_scene = load("res://scenes/programMenu/program/programItemRow.tscn")
	
	_is_ready = true
	# Set initial program name
	on_program_changed(program_resource)
	
	# Connect signals
	back_button.pressed.connect(_on_back_button_pressed)
	save_changes_button.pressed.connect(_on_save_changes_pressed)
	
	insert_item_input.value_changed.connect(_on_insert_position_selected)
	insert_item_button.pressed.connect(_on_insert_item_button_pressed)
	
	insert_item_input.submenu_container_path = sub_menu_container.get_path()

# Called when the program changes (either on open or when updated)
func on_program_changed(new_program: Program) -> void:
	program_resource = new_program
	
	# Only update UI if the node is ready
	if _is_ready:
		if program_resource:
			# Create a deep copy of the program to work on
			_working_program = _copy_program(program_resource)
			program_label.text = _working_program.program_name
			# Load and display program items
			_display_program_items()
		else:
			_working_program = null
			program_label.text = "No Program Selected"
			insert_item_input.set_options_data([])
			_clear_items_display()
		
		# Reset unsaved changes flag
		_has_unsaved_changes = false
		_update_save_button_state()
		
		# Emit signal so parent menus can react
		program_changed.emit(program_resource)

func _copy_program(source: Program) -> Program:
	"""
	Create a deep copy of a Program resource.
	"""
	if not source:
		return null
	
	var copy = Program.new()
	copy.program_name = source.program_name
	
	# Deep copy the items array
	for item in source.items:
		if item.get("type") == "exercise":
			copy.items.append({
				"type": "exercise",
				"exercise_name": item.get("exercise_name", "")
			})
		elif item.get("type") == "superset":
			copy.items.append({
				"type": "superset",
				"exercise_names": item.get("exercise_names", []).duplicate()
			})
	
	return copy

func _mark_unsaved_changes() -> void:
	"""
	Mark that there are unsaved changes and emit signal.
	"""
	_has_unsaved_changes = true
	_update_save_button_state()
	# Emit signal that the working program was modified
	working_program_modified.emit()

func _update_save_button_state() -> void:
	"""
	Update the save button appearance based on unsaved changes.
	"""
	if _has_unsaved_changes:
		save_changes_button.text = "Save Changes *"
		save_changes_button.modulate = Color(1, 1, 0)  # Yellow tint
	else:
		save_changes_button.text = "Save Changes"
		save_changes_button.modulate = Color(1, 1, 1)  # Reset color

func _display_program_items() -> void:
	if not _working_program:
		return
	
	# Clear existing items
	_clear_items_display()
	
	# Get all items from the working program
	var items = _working_program.items
	var option_labels: Array[String] = []
	for item in items:
		option_labels.append(_get_item_display_label(item))
	insert_item_input.set_options_data(option_labels)
	
	if items.is_empty():
		print("no items")
		return
	
	# Debug print all items
	print("Working Program: %s" % _working_program.program_name)
	print("  Total items: %d" % items.size())
	
	for i in range(items.size()):
		var item = items[i]
		var item_type = item.get("type", "")
		
		if item_type == "exercise":
			var exercise_name = item.get("exercise_name", "")
			print("  %d. EXERCISE: %s" % [i + 1, exercise_name])
			
			# Create a row for this exercise
			_create_program_item_row(i, "exercise", exercise_name)
			
		elif item_type == "superset":
			var exercise_names = item.get("exercise_names", [])
			print("  %d. SUPERSET: %s" % [i + 1, ", ".join(exercise_names)])
			
			var display_text = "%d. Superset: %s" % [i + 1, ", ".join(exercise_names)]
			_add_debug_label(display_text)
			
			for j in range(exercise_names.size()):
				print("      %d. %s" % [j + 1, exercise_names[j]])
		else:
			print("  %d. UNKNOWN TYPE: %s" % [i + 1, item_type])
			var display_text = "%d. <unknown type: %s>" % [i + 1, item_type]
			_add_debug_label(display_text)
	
	# After redisplaying, emit working_program_modified to update the pie chart
	# This ensures the pie chart updates when items are reordered or modified
	working_program_modified.emit()

func _create_program_item_row(index: int, item_type: String, exercise_name: String) -> void:
	"""
	Creates a program item row for a single exercise.
	"""
	if not _program_item_row_scene:
		push_error("Program item row scene not loaded")
		return
	
	var row_instance = _program_item_row_scene.instantiate()
	
	# Set up the row with data - use working program
	row_instance.item_index = index
	row_instance.item_type = item_type
	row_instance.exercise_name = exercise_name
	row_instance.program_resource = _working_program  # Use working copy
	
	# Set parent references
	row_instance.parent_menu = self
	row_instance.sub_menu_container = sub_menu_container
	
	# Connect signals from the row
	if row_instance.has_signal("item_modified"):
		row_instance.item_modified.connect(_on_item_modified)
	if row_instance.has_signal("item_deleted"):
		row_instance.item_deleted.connect(_on_item_deleted)
	
	# Add the row to the container
	items_container.add_child(row_instance)

func _get_item_display_label(item: Dictionary) -> String:
	var item_type: String = item.get("type", "")
	if item_type == "exercise":
		return str(item.get("exercise_name", ""))
	if item_type == "superset":
		return "Superset: %s" % ", ".join(item.get("exercise_names", []))
	return "<unknown type: %s>" % item_type

func _on_insert_position_selected(insert_index: int) -> void:
	"""
	Insert a new exercise at the selected position.
	"""
	if not _working_program:
		push_error("No working program available")
		return

	if insert_index < 0 or insert_index > _working_program.items.size():
		push_error("Invalid insert index")
		return
	
	print("Add item at position: %d" % insert_index)
	
	var new_exercise_name = "New Exercise %d" % (_working_program.items.size() + 1)
	
	# Insert into working program
	_working_program.insert_exercise_at(insert_index, new_exercise_name)
	
	# Mark as unsaved (this also emits working_program_modified)
	_mark_unsaved_changes()
	
	# Refresh the display
	_display_program_items()

func _on_item_modified(index: int) -> void:
	"""
	Called when an item in the program is modified.
	"""
	print("Item %d modified" % index)
	
	# Mark as unsaved (this also emits working_program_modified)
	_mark_unsaved_changes()
	
	# Refresh the display to update order numbers
	_display_program_items()

func _on_item_deleted(index: int) -> void:
	"""
	Called when an item is deleted from the program.
	"""
	print("Item %d deleted" % index)
	
	# Mark as unsaved (this also emits working_program_modified)
	_mark_unsaved_changes()
	
	# Refresh the display
	_display_program_items()

func _on_insert_item_button_pressed() -> void:
	# Check if there are any exercises in the container
	if _working_program.items.is_empty():
		# No exercises - directly open exercise picker at position 0
		_on_insert_position_selected(0)
	else:
		# Has exercises - trigger InsertPositionInput
		insert_item_input._on_pressed()

func _on_save_changes_pressed() -> void:
	"""
	Save the working program to the ProgramManager.
	"""
	if not _working_program:
		print("No program to save")
		return
	
	if not program_resource:
		print("No original program to save to")
		return
	
	# Find the program in ProgramManager
	var program_item = DataManager.ProgramManager._get_program_item(program_resource.program_name)
	
	if program_item.is_empty():
		print("Program '%s' not found in ProgramManager" % program_resource.program_name)
		return
	
	# Update the original program with the working copy data
	program_resource.program_name = _working_program.program_name
	program_resource.items = _working_program.items.duplicate(true)  # Deep copy
	
	# Persist the changes to file
	if DataManager.ProgramManager._persist(program_item):
		print("Program saved: ", program_resource.program_name)
		print("Items saved: %d" % program_resource.items.size())
		
		# Reset unsaved changes flag
		_has_unsaved_changes = false
		_update_save_button_state()
		
		# Update the working copy to match the saved state
		_working_program = _copy_program(program_resource)
		
		# Refresh display to ensure everything is in sync
		_display_program_items()
		
		# Emit signal that program changed
		program_changed.emit(program_resource)
		
		NotificationManager.success("Program '%s' saved" % program_resource.program_name)
	else:
		print("Failed to save program: ", program_resource.program_name)
		NotificationManager.error("Failed to save program")

func _clear_items_display() -> void:
	if items_container:
		for child in items_container.get_children():
			child.queue_free()

func _add_debug_label(text: String) -> void:
	if not items_container:
		return
	
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color.WHITE)
	items_container.add_child(label)

func _on_back_button_pressed() -> void:
	# Check for unsaved changes before closing
	if _has_unsaved_changes:
		confirm_dialog.request_confirmation(
			"You have unsaved changes. Are you sure you want to leave?",
			_on_back_confirmed
		)
	else:
		_on_back_confirmed()

func _on_back_confirmed() -> void:
	#request_close() this will cause problems wiht program rows menus references, instead of closing submenu just reload program menu
	MenuManager.switch_to("program")

# Public methods

func has_unsaved_changes() -> bool:
	"""
	Check if there are unsaved changes.
	"""
	return _has_unsaved_changes

func get_working_program() -> Program:
	"""
	Get the working copy of the program.
	"""
	return _working_program
