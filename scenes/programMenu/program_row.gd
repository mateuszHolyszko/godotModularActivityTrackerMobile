extends Control

@export var confirm_dialog: ConfirmationEntryMenu  # Keep this as exported

@export var program_resource: Program = null
@export var submenu_container: Control
@export var parent: Menu
@export var program_menu: Menu # program menu ref, so we can pass correct program to submenu

@onready var program_button: Button = %ProgramButton
@onready var rename_button: TextInputButton = %RenameButton
@onready var delete_button: Button = %DeleteButton

@onready var pie_chart: PieChart = %PieChart

func _ready():
	# Set the program name on the button
	if program_resource:
		program_button.text = program_resource.program_name
		
		# Set up the rename button with the current program name
		rename_button.current_value = program_resource.program_name
		rename_button.prompt_text = "Enter new program name"
		rename_button.placeholder_text = "Program name"
		
		# Update the pie chart with program data
		update_pie_chart()
	
	# Connect signals
	program_button.pressed.connect(_on_program_button_pressed)
	delete_button.pressed.connect(_on_delete_button_pressed)
	
	# Connect rename button signals
	rename_button.value_changed.connect(_on_rename_confirmed)
	
	# Connect sub menu container to the text input button
	rename_button.submenu_container_path = submenu_container.get_path()
	
	# Connect to the program menu's program_changed signal if it exists
	if program_menu and program_menu.has_signal("program_changed"):
		program_menu.program_changed.connect(_on_program_changed)

func update_pie_chart() -> void:
	"""
	Update the pie chart with the program's target muscle breakdown.
	"""
	if not program_resource:
		push_error("ProgramRow: No program resource to update pie chart")
		return
	
	# Get the muscle breakdown for this program
	var breakdown: Dictionary = DataManager.ProgramManager.get_program_target_breakdown(program_resource)
	
	if breakdown.is_empty():
		# No data to show - clear the pie chart
		pie_chart.elements = []
		pie_chart.queue_redraw()
		return
	
	# Convert breakdown to pie chart elements with colors from MuscleDict
	var elements: Array[Dictionary] = []
	for muscle in breakdown:
		var count: int = breakdown[muscle]
		var color: Color = MuscleDict.get_color(muscle)
		
		elements.append({
			"label": muscle,
			"value": count,
			"color": color
		})
	
	# Sort elements by value descending for better visual hierarchy
	elements.sort_custom(func(a, b): return a["value"] > b["value"])
	
	# Set the data on the pie chart
	pie_chart.elements = elements
	pie_chart.queue_redraw()

func _on_program_button_pressed() -> void:
	# Set the program in the program menu before opening
	if program_menu.has_method("on_program_changed"):
		program_menu.on_program_changed(program_resource)
	
	# Open the program submenu
	parent.open_submenu("programMenu", submenu_container)

func _on_program_changed(new_program: Program) -> void:
	# Update the button text if the program name changed
	if new_program:
		program_button.text = new_program.program_name
		program_resource = new_program
		
		# Update rename button's current value to match
		rename_button.current_value = new_program.program_name
		
		# Update the pie chart with the new program data
		update_pie_chart()

func _on_rename_confirmed(new_name: String) -> void:
	"""
	Handle the rename confirmation from TextInputButton.
	"""
	if not program_resource:
		push_error("No program resource to rename")
		return
	
	if new_name.strip_edges().is_empty():
		NotificationManager.error("Program name cannot be empty")
		return
	
	var old_name := program_resource.program_name
	var new_name_clean := new_name.strip_edges()
	
	# Check if the name actually changed
	if old_name == new_name_clean:
		print("Program name unchanged")
		return
	
	# Check if a program with the new name already exists
	var existing_program := DataManager.ProgramManager.get_program(new_name_clean)
	if existing_program:
		NotificationManager.error("A program named '%s' already exists" % new_name_clean)
		# Revert the rename button's value
		rename_button.current_value = old_name
		return
	
	# Perform the rename
	var renamed := DataManager.ProgramManager.rename_program(old_name, new_name_clean)
	
	if renamed:
		# Update the button text
		program_button.text = new_name_clean
		
		# Update the resource reference
		program_resource.program_name = new_name_clean
		
		# Update the rename button's current value
		rename_button.current_value = new_name_clean
		
		print("Program renamed from '%s' to '%s'" % [old_name, new_name_clean])
		NotificationManager.success("Program renamed to '%s'" % new_name_clean)
		
		# Refresh the list in the parent to update any other references
		if parent and parent.has_method("refresh_programs"):
			parent.refresh_programs()
	else:
		NotificationManager.error("Failed to rename program")
		# Revert the rename button's value
		rename_button.current_value = old_name

func _on_delete_button_pressed() -> void:
	# Check if confirm_dialog is available
	if not confirm_dialog:
		push_error("Confirm dialog not set for program row")
		return
	
	# Request confirmation before deleting
	var program_name := program_resource.program_name
	var confirm_message := "Delete program '%s'?" % program_name
	
	# The container parameter is now optional, so we don't need to pass it
	confirm_dialog.request_confirmation(
		confirm_message,
		_on_delete_confirmed
	)

func _on_delete_confirmed() -> void:
	# Delete the program from DataManager
	if not program_resource:
		push_error("No program resource to delete")
		return
	
	var program_name := program_resource.program_name
	var deleted := DataManager.ProgramManager.remove_program(program_name)
	
	if deleted:
		print("Program '%s' deleted successfully" % program_name)
		
		# Remove this row from the container
		queue_free()
		
		# Refresh the list in the parent
		if parent and parent.has_method("refresh_programs"):
			parent.refresh_programs()
	else:
		push_error("Failed to delete program '%s'" % program_name)

# Optional: Handle cancellation if you want to do something specific
func _on_delete_cancelled() -> void:
	print("Delete cancelled for program: ", program_resource.program_name)
