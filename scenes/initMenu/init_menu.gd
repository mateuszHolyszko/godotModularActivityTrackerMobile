extends Menu

@onready var VolumePanel: Panel = %VolumePanel
@onready var ModelCarrouselViewportContainer: SubViewportContainer = %ModelCarrouselViewportContainer
@onready var weight_label: Label = %WeightLabel

# === Sub Menu
@onready var submenu_container: Control = %SubMenuContainer
@onready var inputMenuButton: Button = %InputMesurmentsButton
const INPUT_MEASUREMENTS_SCENE_PATH := "res://scenes/initMenu/inputMesurmentsMenu/inputMesurmentsMenu.tscn"
var _input_measurements_menu: Menu

# Single source of truth for focused muscle
var focused_muscle: String = ""

func _ready():
	# Connect to VolumePanel's signal
	if VolumePanel and VolumePanel.has_signal("muscle_selected"):
		VolumePanel.muscle_selected.connect(_on_muscle_selected)
		
	_input_measurements_menu = load(INPUT_MEASUREMENTS_SCENE_PATH).instantiate()
	add_submenu("inputMeasurements", _input_measurements_menu)

	inputMenuButton.pressed.connect(_on_open_measurements_pressed)
	
	# Update the weight label with the latest measurement
	_update_weight_label()

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
