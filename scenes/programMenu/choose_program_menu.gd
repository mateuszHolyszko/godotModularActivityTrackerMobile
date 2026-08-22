extends Menu

@onready var _confirm_dialog: ConfirmationEntryMenu = %ConfirmationEntryMenu
@onready var programs_container: VBoxContainer = %ScrollContent
@onready var add_program_button: Button = %AddProgramButton

@onready var programs_summary: VFlowContainer = %ProgramsSummaryVFlow

# === Sub Menu
@onready var submenu_container: Control = %SubMenuContainer
const PROGRAM_MENU_SCENE_PATH := "res://scenes/programMenu/program/programMenu.tscn"
var _program_menu: Menu

var _program_row_scene: PackedScene = null


func _ready():
	# Load the program row scene once and cache it
	_program_row_scene = load("res://scenes/programMenu/programRow.tscn")
	
	_program_menu = load(PROGRAM_MENU_SCENE_PATH).instantiate()
	add_submenu("programMenu", _program_menu)
	
	# Connect to program menu's program_changed signal
	if _program_menu.has_signal("program_changed"):
		_program_menu.program_changed.connect(_on_program_changed)
	
	# Connect the add program button
	add_program_button.pressed.connect(_on_add_program_button_pressed)
	
	# Populate the programs list
	_populate_programs()

func _populate_programs() -> void:
	# Clear existing rows
	for child in programs_container.get_children():
		child.queue_free()
	
	# Get all programs from DataManager
	var programs: Array[Program] = DataManager.ProgramManager.get_all_program_objects()
	
	# Create a row for each program
	for program in programs:
		_create_program_row(program)

func _create_program_row(program: Program) -> void:
	if not _program_row_scene:
		push_error("Program row scene not loaded")
		return
	
	var row_instance = _program_row_scene.instantiate()
	
	# Set the program resource
	row_instance.program_resource = program
	
	# Set the submenu container reference
	row_instance.submenu_container = submenu_container
	
	# Set parent and program menu references
	row_instance.parent = self
	row_instance.program_menu = _program_menu
	
	# Pass dialog confirm
	row_instance.confirm_dialog = _confirm_dialog
	
	# Add the row to the container
	programs_container.add_child(row_instance)

# Called when the program menu changes a program
func _on_program_changed(new_program: Program) -> void:
	# Refresh the list to show updated program names
	refresh_programs()

func refresh_programs() -> void:
	_populate_programs()
	programs_summary.update_summary()

func add_new_program(program: Program) -> void:
	_create_program_row(program)
	
func _on_add_program_button_pressed() -> void:
	const NEW_PROGRAM_NAME := "New Program"
	
	# Check if "New Program" already exists
	var existing_program := DataManager.ProgramManager.get_program(NEW_PROGRAM_NAME)
	
	if existing_program:
		# Notify user that the program already exists
		NotificationManager.info("New program already added")
		return
	
	# Add the new program
	var new_program := DataManager.ProgramManager.add_program(NEW_PROGRAM_NAME)
	
	if new_program:
		# Add the program row to the UI
		add_new_program(new_program)
		
		NotificationManager.success("New program added")
