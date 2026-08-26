extends Menu

@onready var scroll_content: VBoxContainer = %ScrollContent
@onready var start_program_button_template: Button = %StartProgramButton_tamplate
@onready var volume_chart_2d_template: VolumeChart2D = %VolumeChart2DTemplate  
@onready var session_history_container: SessionHistoryContainer = %SessionHistoryContainer
@onready var volume_summary_panel: VolumeSummaryPanel = %VolumeSummaryPanel

@onready var loading_panel: LoadingPanel = %LoadingPanel

# === Sub Menu
@onready var submenu_container: Control = %SubMenuContainer
const WORKOUT_MENU_SCENE_PATH := "res://scenes/sessionMenu/workoutMenu/workoutMenu.tscn"
var _workout_menu: Menu


func _ready():
	DataManager.ProgramManager.programs_changed.connect(_populate_program_buttons) # Update when programs get changed to reflect new changes
	
	is_persistent = true # Set to be persisent menu
	_populate_program_buttons()
	refresh()

func refresh() -> void:
	volume_summary_panel.refresh()
	session_history_container.refresh()

func _populate_program_buttons() -> void:
	
	# Get all programs using the autoloaded DataManager
	var programs = DataManager.ProgramManager.get_all_program_objects()
	
	# Clear existing items (keep template hidden)
	for child in scroll_content.get_children():
		if child != start_program_button_template and child != volume_chart_2d_template:
			child.queue_free()
	
	# Create a container for each program
	for program in programs:
		# Create a VBoxContainer for this program
		var program_container := VBoxContainer.new()
		program_container.custom_minimum_size = Vector2(0, 150)
		program_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		program_container.add_theme_constant_override("separation", 8)
		
		# Create and setup the button
		var button = start_program_button_template.duplicate()
		button.text = program.program_name
		button.visible = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_program_button_pressed.bind(program))
		
		# Create and setup the chart
		var chart = volume_chart_2d_template.duplicate()
		chart.visible = true
		chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chart.set_program(program.program_name)
		
		# Add both to the container
		program_container.add_child(button)
		program_container.add_child(chart)
		
		# Add the container to the scroll content
		scroll_content.add_child(program_container)

func _on_program_button_pressed(program: Program) -> void:
	# Check that a weight measurement exists before starting the workout
	var last_weight = DataManager.MeasurementManager.get_last_measurement("weight")
	if last_weight.is_empty():
		NotificationManager.error("No weight measurement found. Please log your weight before starting a workout.",6)
		#push_warning("No weight measurement found. Please log your weight before starting a workout.")
		return
	
	var seconds_in_month := 30 * 24 * 60 * 60
	var now := Time.get_unix_time_from_system()
	if now - last_weight.timestamp > seconds_in_month:
		NotificationManager.warning("Your weight hasn't been updated in over a month")
		#push_warning("Your weight hasn't been updated in over a month (last recorded: %s)." % last_weight.date)
	
	# Register submenu
	_workout_menu = load(WORKOUT_MENU_SCENE_PATH).instantiate()
	add_submenu("workoutMenu", _workout_menu)
	_workout_menu.closed.connect(refresh)
	
	# Create a new WorkoutSession and store it in GlobalElements
	GlobalElements.set_current_workout( WorkoutSession.new() ) 
	
	# Add it as a child of GlobalElements so it can receive signals and be managed
	GlobalElements.add_child(GlobalElements.CurrentWorkout)
	
	# Start the workout with the selected program
	GlobalElements.CurrentWorkout.start_workout(program)
	
	open_submenu("workoutMenu", submenu_container)
	
	print("Started workout with program: ", program.program_name)
