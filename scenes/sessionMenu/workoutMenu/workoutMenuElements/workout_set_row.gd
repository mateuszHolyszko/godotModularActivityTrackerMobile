extends Control

@export var sub_menu_container: Container 

@onready var bg_rect: ColorRect = %BG_rect

@onready var set_number_label: Label = %SetNumber
@onready var input_weight_button: NumericInputButton = %InputWeightButton
@onready var calisthenic_added_weight_label: Label = %CalisthenicAddedWeightLabel
@onready var input_reps_button: NumericInputButton = %RepsWeightButton

@onready var last_reps_label: Label = %LastRepsEntryLabel
@onready var last_weight_label: Label = %LastWeightEntryLabel

@onready var too_few_reps_indicator_tex_rect: TextureRect = %TooLowIndicatorTR
@onready var too_many_reps_indicator_tex_rect: TextureRect = %TooHighIndicatorTR

# References to parent data
var exercise_index: int = -1
var set_index: int = -1
var set_data: Dictionary = {}  # {order: int, weight: float, reps: int}

# Flag to track if we've been setup
var _is_setup: bool = false
var _is_initializing := false
# Flag to track if _ready has run
var _ready_called: bool = false
var is_edited: bool = false
var _edit_tween: Tween
var _default_bg_color: Color
var _preserve_edit_state: bool = false

var is_bodyweight: bool

func _ready():
	_ready_called = true
	_default_bg_color = bg_rect.color
	_update_edit_visual()
	
	# Set up numeric input buttons
	input_weight_button.submenu_container_path = sub_menu_container.get_path()
	input_reps_button.submenu_container_path = sub_menu_container.get_path()
	
	# Connect value changed signals
	input_weight_button.value_confirmed.connect(_on_weight_changed) # Dont use value_changed signal, since in case of bw exercises we adjust weight in code, that calls value_change causing infinit recursion
	input_reps_button.value_confirmed.connect(_on_reps_changed)
	
	# If we were already setup, complete the initialization now
	if _is_setup:
		_finish_setup()
		

func setup(p_set_data: Dictionary, p_exercise_index: int, p_set_index: int, preserve_edit_state: bool = false) -> void:
	"""Setup the row with set data, exercise index, and set index"""
	set_data = p_set_data
	exercise_index = p_exercise_index
	set_index = p_set_index
	_preserve_edit_state = preserve_edit_state
	# Mark as setup
	_is_setup = true
	
	# Check if exercise is bodyweight
	is_bodyweight = GlobalElements.CurrentWorkout.get_exercise_data_at(exercise_index).exercise.bodyweight
	
	# If ready already ran, finish setup now
	if _ready_called:
		_finish_setup()

func _finish_setup() -> void:
	"""Complete the setup after all nodes are ready"""
	_is_initializing = true
	if not _preserve_edit_state:
		is_edited = false
		_update_edit_visual()
	# Update the set number label
	set_number_label.text = str(set_index + 1)
	_update_muscle_color( GlobalElements.CurrentWorkout.get_exercise_data_at(exercise_index).exercise.name )
	
	#print("IS_BW: ", is_bodyweight)
	
	if is_bodyweight == false:
		# Set initial values from the set data
		if set_data and set_data.has("weight"):
			input_weight_button.current_value = set_data.get("weight", 0.0)
			input_weight_button.text = "--"
			last_weight_label.text = str("Last Weight: ", set_data.get("weight", 0.0))
	else:
		# NOTE this is historic data so when we get bodyweight we cant do CurrentWorkout.get_body_weight() we need to get via last entry.session.bodyweight
		# get Historic BW if there is no last entry defult to current weight!
		var historic_bw := DataManager.SessionManager.get_session_by_id(  DataManager.ExerciseEntryManager.get_latest_entry_for_exercise( GlobalElements.CurrentWorkout.get_exercise_data_at(exercise_index).exercise.name ).session_id  ).body_weight
		print("HISTORIC BW: ", historic_bw)
		
		if set_data and set_data.has("weight"):
			var added_weight = set_data.get("weight", 0.0) - historic_bw
			input_weight_button.current_value = added_weight
			input_weight_button.text = "--"
			last_weight_label.text = str("W: ", added_weight, " BW: ", historic_bw)

	if set_data and set_data.has("reps"):
		input_reps_button.current_value = set_data.get("reps", 0)
		input_reps_button.text = "--"
		last_reps_label.text = str( "Last Repst: ", set_data.get("reps", 0) )
	
	_is_initializing = false

func set_edit_state(edited: bool) -> void:
	is_edited = edited
	_update_edit_visual()

func _update_edit_visual() -> void:
	if not _ready_called:
		return

	if _edit_tween and _edit_tween.is_valid():
		_edit_tween.kill()

	bg_rect.visible = true
	if is_edited:
		bg_rect.visible = false
		return

	# Classic terminal blinking block
	bg_rect.color = Color(0.0, 0.0, 0.0, 0.0)  # Transparent normally
	bg_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	_edit_tween = create_tween().set_loops()
	_edit_tween.set_trans(Tween.TRANS_SPRING)  # Instant step for sharp blink
	_edit_tween.set_ease(Tween.EASE_IN_OUT)
	_edit_tween.tween_property(bg_rect, "color:a", 0.4, 0.5)  # Semi-transparent white block
	_edit_tween.tween_property(bg_rect, "color:a", 0.0, 0.5)

func _on_weight_changed(new_weight: float) -> void:
	"""Handle weight value change"""
	if _is_initializing:
		return
	
	is_edited = true
	_update_edit_visual()
	_update_rep_range_indicators_visual()
		
	if not GlobalElements.CurrentWorkout or not GlobalElements.CurrentWorkout.is_active():
		return
	
	if exercise_index < 0 or set_index < 0:
		return
	
	var success = GlobalElements.CurrentWorkout.update_set(
		exercise_index,
		set_index,
		new_weight,
		int(input_reps_button.current_value),
		is_bodyweight
	)
	
	# If its bodyweight, show label that indicates how much weight is added to bodyweight
	if is_bodyweight:
		calisthenic_added_weight_label.show() 
		calisthenic_added_weight_label.text = str(new_weight)
	
	if not success:
		push_error("Failed to update set weight")

func _on_reps_changed(new_reps: float) -> void:
	"""Handle reps value change"""
	if _is_initializing:
		return

	is_edited = true
	_update_edit_visual()
	_update_rep_range_indicators_visual()
		
	if not GlobalElements.CurrentWorkout or not GlobalElements.CurrentWorkout.is_active():
		return
	
	if exercise_index < 0 or set_index < 0:
		return
	
	# Update the workout session data
	var success = GlobalElements.CurrentWorkout.update_set(
		exercise_index,
		set_index,
		input_weight_button.current_value,
		int(new_reps)  # Convert to int for reps
	)
	
	if not success:
		push_error("Failed to update set reps")

func refresh() -> void:
	"""Manually refresh the set values from the workout data"""
	if not GlobalElements.CurrentWorkout or not GlobalElements.CurrentWorkout.is_active():
		return
	
	if exercise_index < 0 or set_index < 0:
		return
	
	# Get the updated set data from the workout
	var exercise_data = GlobalElements.CurrentWorkout.get_exercise_data_at(exercise_index)
	if not exercise_data:
		return
	
	var sets = exercise_data.sets
	if set_index >= sets.size():
		return
	
	var updated_set_data = sets[set_index]
	if updated_set_data:
		set_data = updated_set_data
		input_weight_button.current_value = set_data.get("weight", 0.0)
		input_reps_button.current_value = set_data.get("reps", 0)
		#print("TEST:   ",set_data.get("reps", 0))

func _update_muscle_color(exercise_name: String) -> void:
	"""Update the background color of UI elements based on the exercise's target muscle"""
	# Get the target muscle for this exercise
	var target_muscle = DataManager.ExerciseManager.get_exercise_target_muscle(exercise_name)
	
	# Get the color from MuscleDict
	var muscle_color = MuscleDict.get_color(target_muscle)
	
	# Apply color to pick_exercise_button background only
	if set_number_label:
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = muscle_color
		set_number_label.add_theme_stylebox_override("normal", stylebox)

func _update_rep_range_indicators_visual() -> void:
	"""Update the visibility of the too few/too many reps indicators based on the current reps value"""
	if not GlobalElements.CurrentWorkout or not GlobalElements.CurrentWorkout.is_active():
		return
	
	if exercise_index < 0 or set_index < 0:
		return
	
	var exercise_data = GlobalElements.CurrentWorkout.get_exercise_data_at(exercise_index)
	if not exercise_data or not exercise_data.exercise:
		return
	
	var exercise = exercise_data.exercise
	var current_reps = int(input_reps_button.current_value)
	
	# Check against the exercise's rep range
	if current_reps < exercise.rep_range.x:
		too_few_reps_indicator_tex_rect.visible = true
		NotificationManager.warning("Too few reps!\nConsider lowering weight")
	else:
		too_few_reps_indicator_tex_rect.visible = false
	
	if current_reps > exercise.rep_range.y:
		too_many_reps_indicator_tex_rect.visible = true
		NotificationManager.success("Too many reps!\nConsider increasing weight")
	else:
		too_many_reps_indicator_tex_rect.visible = false

"""

func _exit_tree() -> void: DO NOT USE _exit_tree in persistent menus
	#Clean up when the node is removed
	# Disconnect signals
	if input_weight_button.value_changed.is_connected(_on_weight_changed):
		input_weight_button.value_changed.disconnect(_on_weight_changed)
	if input_reps_button.value_changed.is_connected(_on_reps_changed):
		input_reps_button.value_changed.disconnect(_on_reps_changed)
"""
