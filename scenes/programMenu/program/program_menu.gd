extends Menu

@export var program_resource: Program = null

@onready var program_label: Label = %ProgramNameLabel
@onready var back_button: Button = %BackButton
@onready var save_changes_button: Button = %SaveButton
@onready var items_container: VBoxContainer = %ItemsContainer  # Add this to your scene

# Signal to notify when the program changes
signal program_changed(new_program: Program)

var _is_ready: bool = false

func _ready():
	_is_ready = true
	# Set initial program name
	on_program_changed(program_resource)
	
	# Connect signals
	back_button.pressed.connect(_on_back_button_pressed)
	save_changes_button.pressed.connect(_on_save_changes_pressed)

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
	
	if items.is_empty():
		_add_debug_label("(no items)")
		return
	
	# Debug print all items
	print("Program: %s" % program_resource.program_name)
	print("  Total items: %d" % items.size())
	
	for i in range(items.size()):
		var item = items[i]
		var item_type = item.get("type", "")
		
		if item_type == "exercise":
			var exercise_name = item.get("exercise_name", "")
			var display_text = "%d. Exercise: %s" % [i + 1, exercise_name]
			_add_debug_label(display_text)
			print("  %d. EXERCISE: %s" % [i + 1, exercise_name])
			
		elif item_type == "superset":
			var exercise_names = item.get("exercise_names", [])
			var display_text = "%d. Superset: %s" % [i + 1, ", ".join(exercise_names)]
			_add_debug_label(display_text)
			print("  %d. SUPERSET: %s" % [i + 1, ", ".join(exercise_names)])
			
			# Print individual exercises in superset
			for j in range(exercise_names.size()):
				print("      %d. %s" % [j + 1, exercise_names[j]])
		else:
			var display_text = "%d. <unknown type: %s>" % [i + 1, item_type]
			_add_debug_label(display_text)
			print("  %d. UNKNOWN TYPE: %s" % [i + 1, item_type])

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
