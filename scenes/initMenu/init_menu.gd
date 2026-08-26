extends Menu

@onready var VolumePanel: Panel = %VolumePanel
@onready var ModelCarrouselViewportContainer: SubViewportContainer = %ModelCarrouselViewportContainer
@onready var weight_label: Label = %WeightLabel

# Switch model buttons
@onready var body_model_button: Button = %BodyButton
@onready var arm_model_button: Button = %ArmButton
@onready var leg_model_button: Button = %LegButton

# === Sub Menu
@onready var submenu_container: Control = %SubMenuContainer
@onready var inputMenuButton: Button = %InputMesurmentsButton
const INPUT_MEASUREMENTS_SCENE_PATH := "res://scenes/initMenu/inputMesurmentsMenu/inputMesurmentsMenu.tscn"
var _input_measurements_menu: Menu

# Single source of truth for focused muscle
var focused_muscle: String = ""

# Map buttons to their corresponding model names
var model_buttons: Dictionary = {}

func _ready():
	# Connect to VolumePanel's signal
	if VolumePanel and VolumePanel.has_signal("muscle_selected"):
		VolumePanel.muscle_selected.connect(_on_muscle_selected)
		
	_input_measurements_menu = load(INPUT_MEASUREMENTS_SCENE_PATH).instantiate()
	add_submenu("inputMeasurements", _input_measurements_menu)

	inputMenuButton.pressed.connect(_on_open_measurements_pressed)
	
	# Setup model buttons
	_setup_model_buttons()
	
	# Update the weight label with the latest measurement
	_update_weight_label()

func _setup_model_buttons() -> void:
	"""
	Setup all model buttons with toggle mode and connections.
	"""
	# Map buttons to their model names
	model_buttons = {
		body_model_button: "body",
		arm_model_button: "arm",
		leg_model_button: "leg"
	}
	
	# Configure all buttons as toggles
	for button in model_buttons.keys():
		button.toggle_mode = true
		button.pressed.connect(_on_model_button_pressed.bind(button))
	
	# Set default selection (e.g., body model)
	body_model_button.button_pressed = true

func _on_model_button_pressed(button: Button) -> void:
	"""
	Handle model button presses with automatic untoggling of other buttons.
	"""
	# Get the model name for this button
	var model_name = model_buttons.get(button)
	if not model_name:
		return
	
	# Untoggle all other buttons
	for other_button in model_buttons.keys():
		if other_button != button:
			other_button.button_pressed = false
	
	# Switch the model display
	ModelCarrouselViewportContainer.switch_to_display(model_name)

func _on_muscle_selected(muscle_name: String):
	"""
	Handle muscle selection from the VolumePanel.
	"""
	focused_muscle = muscle_name
	update_model_carrousel_focus(muscle_name)
	
	print("Menu: Focus changed to: ", muscle_name if muscle_name != "" else "None")

func update_model_carrousel_focus(muscle_name: String):
	"""
	Update the focus in the ModelCarrousel container.
	"""
	ModelCarrouselViewportContainer.set_focused_muscle(muscle_name)
	
func _on_open_measurements_pressed() -> void:
	open_submenu("inputMeasurements", submenu_container)

func _update_weight_label() -> void:
	"""
	Query the last recorded weight and update the label.
	"""
	var last_weight = DataManager.MeasurementManager.get_last_measurement("weight")
	
	if last_weight.is_empty():
		# No weight data available
		weight_label.text = "BW: -- kg"
	else:
		# Format the weight with 2 decimal places
		weight_label.text = "BW: %.2f kg" % last_weight.value
