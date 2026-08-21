extends Menu

@export var program_resource: Program = null

@onready var program_label: Label = %ProgramNameLabel
@onready var back_button: Button = %BackButton
@onready var save_changes_button: Button = %SaveButton
@onready var items_container: VBoxContainer =  %ScrollContent

@onready var add_item_button: Button = %AddItemButtonTemplate # this is disabled label, duplicate it and add it programmatically
@onready var toggle_add_buttons_button: Button = %AddButtonToggle

@onready var sub_menu_container: Container = %SubMenuContainer
@onready var confirm_dialog: ConfirmationEntryMenu = %ConfirmationEntryMenu

# Signal to notify when the program changes
signal program_changed(new_program: Program)

var _is_ready: bool = false
var _add_buttons_visible: bool = false  # Track visibility state

var _program_item_row_scene: PackedScene = null

func _ready():
	# Load the program item row scene once and cache it
	_program_item_row_scene = load("res://scenes/programMenu/program/programItemRow.tscn")
	
	_is_ready = true
	# Set initial program name
	on_program_changed(program_resource)
	
	# Connect signals
	back_button.pressed.connect(_on_back_button_pressed)
	save_changes_button.pressed.connect(_on_save_changes_pressed)
	toggle_add_buttons_button.toggled.connect(_on_toggle_add_buttons_toggled)
	
	# Set initial toggle state
	toggle_add_buttons_button.button_pressed = false
	toggle_add_buttons_button.text = "Insert new exercise"
	
	# Hide the template button (it's just for copying)
	add_item_button.visible = false

# Called when the program changes (either on open or when updated)
func on_program_changed(new_program: Program) -> void:
	program_resource = new_program
	
	# Only update UI if the node is ready
	if _is_ready:
		if program_resource:
			program_label.text = program_resource.program_name
			# Load and display program items
			_display_program_items()
		else:
			program_label.text = "No Program Selected"
			_clear_items_display()
		
		# Emit signal so parent menus can react
		program_changed.emit(program_resource)

func _display_program_items() -> void:
	if not program_resource:
		return
	
	# Clear existing items
	_clear_items_display()
	
	# Get all items from the program
	var items = program_resource.items
	
	# Add an add button at the top (before any items)
	_add_add_button(0)
	
	if items.is_empty():
		_add_debug_label("(no items)")
		# Apply visibility to all add buttons
		_update_add_buttons_visibility()
		return
	
	# Debug print all items
	print("Program: %s" % program_resource.program_name)
	print("  Total items: %d" % items.size())
	
	for i in range(items.size()):
		var item = items[i]
		var item_type = item.get("type", "")
		
		if item_type == "exercise":
			var exercise_name = item.get("exercise_name", "")
			print("  %d. EXERCISE: %s" % [i + 1, exercise_name])
			
			# Create a row for this exercise
			_create_program_item_row(i, "exercise", exercise_name)
			
			# Add an add button after this item
			_add_add_button(i + 1)
			
		elif item_type == "superset":
			var exercise_names = item.get("exercise_names", [])
			print("  %d. SUPERSET: %s" % [i + 1, ", ".join(exercise_names)])
			
			# For now, just show as debug label (superset will be implemented later)
			var display_text = "%d. Superset: %s" % [i + 1, ", ".join(exercise_names)]
			_add_debug_label(display_text)
			
			# Add an add button after this item
			_add_add_button(i + 1)
			
			# Print individual exercises in superset
			for j in range(exercise_names.size()):
				print("      %d. %s" % [j + 1, exercise_names[j]])
		else:
			print("  %d. UNKNOWN TYPE: %s" % [i + 1, item_type])
			var display_text = "%d. <unknown type: %s>" % [i + 1, item_type]
			_add_debug_label(display_text)
			
			# Add an add button after this item
			_add_add_button(i + 1)
	
	# Apply visibility to all add buttons based on current state
	_update_add_buttons_visibility()

func _create_program_item_row(index: int, item_type: String, exercise_name: String) -> void:
	"""
	Creates a program item row for a single exercise.
	"""
	if not _program_item_row_scene:
		push_error("Program item row scene not loaded")
		return
	
	var row_instance = _program_item_row_scene.instantiate()
	
	# Set up the row with data
	row_instance.item_index = index
	row_instance.item_type = item_type
	row_instance.exercise_name = exercise_name
	row_instance.program_resource = program_resource
	
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

func _add_add_button(index: int) -> void:
	"""
	Add an 'Add Item' button at the specified index position.
	"""
	if not add_item_button:
		push_error("Add item button template not found")
		return
	
	# Duplicate the template button
	var new_button = add_item_button.duplicate()
	new_button.visible = true
	new_button.text = "+"
	
	# Store the position index in the button
	new_button.set_meta("insert_index", index)
	
	# Connect the button's pressed signal
	new_button.pressed.connect(_on_add_item_button_pressed.bind(new_button))
	
	# Add to container
	items_container.add_child(new_button)

func _update_add_buttons_visibility() -> void:
	"""
	Update the visibility of all add buttons in the container.
	"""
	if not items_container:
		return
	
	for child in items_container.get_children():
		# Check if this is an add button (has the insert_index meta)
		if child is Button and child.has_meta("insert_index"):
			child.visible = _add_buttons_visible

func _on_toggle_add_buttons_toggled(button_pressed: bool) -> void:
	"""
	Handle the toggle button state change.
	"""
	_add_buttons_visible = button_pressed
	
	# Update button text
	if button_pressed:
		toggle_add_buttons_button.text = "Hide +"
	else:
		toggle_add_buttons_button.text = "Insert new exercise"
	
	# Update visibility of all add buttons
	_update_add_buttons_visibility()
	
	print("Add buttons visibility: %s" % _add_buttons_visible)

func _on_add_item_button_pressed(button: Button) -> void:
	"""
	Handle when an add item button is pressed.
	"""
	var insert_index = button.get_meta("insert_index", -1)
	if insert_index < 0:
		push_error("Invalid insert index")
		return
	
	print("Add item at position: %d" % insert_index)
	
	# For now, add an empty exercise item at the specified position
	# Later we can open a menu to choose exercise type
	var new_exercise_name = "New Exercise %d" % (program_resource.items.size() + 1)
	
	# Insert the new item at the specified position
	program_resource.insert_exercise_at(insert_index, new_exercise_name)
	
	# Refresh the display
	_display_program_items()
	
	# Save changes
	_on_save_changes_pressed()
	
	print("Added new item at position %d" % insert_index)

func _on_item_modified(index: int) -> void:
	"""
	Called when an item in the program is modified.
	"""
	print("Item %d modified, saving changes..." % index)
	_on_save_changes_pressed()
	
	# Refresh the entire display to update all order numbers
	_display_program_items()

func _on_item_deleted(index: int) -> void:
	"""
	Called when an item is deleted from the program.
	"""
	print("Item %d deleted, saving changes..." % index)
	_on_save_changes_pressed()
	
	# Refresh the entire display
	_display_program_items()

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
	request_close()

func _on_save_changes_pressed() -> void:
	if not program_resource:
		print("No program to save")
		return
	
	# Save any changes made to the program using ProgramManager
	# First, find the program in ProgramManager
	var program_name = program_resource.program_name
	var program_item = DataManager.ProgramManager._get_program_item(program_name)
	
	if program_item.is_empty():
		print("Program '%s' not found in ProgramManager" % program_name)
		return
	
	# Persist the changes to file
	if DataManager.ProgramManager._persist(program_item):
		print("Program saved: ", program_resource.program_name)
		print("Items saved: %d" % program_resource.items.size())
		
		# Debug print saved items
		print("Saved items:")
		for i in range(program_resource.items.size()):
			var item = program_resource.items[i]
			if item.get("type") == "exercise":
				print("  %d. EXERCISE: %s" % [i + 1, item.get("exercise_name", "")])
			elif item.get("type") == "superset":
				print("  %d. SUPERSET: %s" % [i + 1, ", ".join(item.get("exercise_names", []))])
	else:
		print("Failed to save program: ", program_resource.program_name)

# Optional: Add a method to test adding items
func _test_add_items() -> void:
	if not program_resource:
		return
	
	# Add some test items
	program_resource.add_exercise("Test Squat")
	program_resource.add_exercise("Test Bench Press")
	program_resource.add_superset(["Test Pullup", "Test Deadlift"])
	
	# Refresh display
	_display_program_items()
	
	# Auto-save after adding items
	_on_save_changes_pressed()

# Public method to add a new item to the program
func add_item_to_program(item_type: String, data) -> bool:
	"""
	Add a new item to the program.
	item_type: "exercise" or "superset"
	data: exercise_name (String) for exercise, or Array of exercise names for superset
	"""
	if not program_resource:
		push_error("No program resource loaded")
		return false
	
	if item_type == "exercise":
		var exercise_name = str(data).strip_edges()
		if exercise_name.is_empty():
			push_error("Exercise name cannot be empty")
			return false
		
		program_resource.add_exercise(exercise_name)
		_display_program_items()
		_on_save_changes_pressed()
		return true
		
	elif item_type == "superset":
		var exercise_names: Array = data
		if exercise_names.is_empty():
			push_error("Superset must have at least one exercise")
			return false
		
		program_resource.add_superset(exercise_names)
		_display_program_items()
		_on_save_changes_pressed()
		return true
	
	else:
		push_error("Unknown item type: %s" % item_type)
		return false
