extends Menu

@onready var scroll_content: VBoxContainer = %ScrollContent
@onready var start_program_button_template: Button = %StartProgramButton_tamplate

# === Sub Menu
@onready var submenu_container: Control = %SubMenuContainer
const WORKOUT_MENU_SCENE_PATH := "res://scenes/sessionMenu/workoutMenu/workoutMenu.tscn"
var _workout_menu: Menu


func _ready():
	_populate_program_buttons()

func _populate_program_buttons() -> void:
	
	# Register submenu
	_workout_menu = load(WORKOUT_MENU_SCENE_PATH).instantiate()
	add_submenu("workoutMenu", _workout_menu)
	
	# Get all programs using the autoloaded DataManager
	var programs = DataManager.ProgramManager.get_all_program_objects()
	
	# Clear existing buttons (keep template hidden)
	for child in scroll_content.get_children():
		if child != start_program_button_template:
			child.queue_free()
	
	# Create a button for each program
	for program in programs:
		var button = start_program_button_template.duplicate()
		button.text = program.program_name
		button.visible = true
		
		# Connect the button press with the program
		button.pressed.connect(_on_program_button_pressed.bind(program))
		
		scroll_content.add_child(button)

func _on_program_button_pressed(program: Program) -> void:
	# Create a new WorkoutSession and store it in GlobalElements
	GlobalElements.CurrentWorkout = WorkoutSession.new()
	
	# Add it as a child of GlobalElements so it can receive signals and be managed
	GlobalElements.add_child(GlobalElements.CurrentWorkout)
	
	# Start the workout with the selected program
	GlobalElements.CurrentWorkout.start_workout(program)
	
	open_submenu("workoutMenu", submenu_container)
	
	print("Started workout with program: ", program.program_name)
