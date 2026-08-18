extends Node

@onready var vertical_box: VBoxContainer = %VB

# Signal to notify when a muscle is selected
signal muscle_selected(muscle_name: String)

# Track the currently focused muscle
var focused_muscle: String = ""

# Reference to the main menu (set by parent)
var main_menu: Node = null

func _ready():
	create_muscle_buttons()
	
	# Find the main menu parent
	main_menu = get_parent()
	while main_menu and not main_menu is Menu:
		main_menu = main_menu.get_parent()

func create_muscle_buttons():
	"""
	Create a MuscleButton for each muscle group and enable toggle mode.
	"""
	# Clear any existing children
	for child in vertical_box.get_children():
		child.queue_free()
	
	# Get all muscle groups
	var muscle_groups = MuscleDict.MUSCLE_COLORS.keys()
	muscle_groups.sort()
	
	# Create a MuscleButton for each muscle
	for muscle_name in muscle_groups:
		var button = MuscleButton.new()
		button.text = muscle_name
		
		# Make button expand horizontally AND vertically
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		# PROGRAMMATICALLY ENABLE TOGGLE MODE for this instance
		button.toggle_mode = true
		
		# Connect the toggled signal instead of pressed
		button.toggled.connect(_on_muscle_button_toggled.bind(button))
		
		vertical_box.add_child(button)

func _on_muscle_button_toggled(button_pressed: bool, button: MuscleButton):
	"""
	Handle muscle button toggle.
	"""
	var muscle_name = button.text
	
	if button_pressed:
		# Button is being toggled ON - untoggle all others first
		for child in vertical_box.get_children():
			if child is MuscleButton and child != button:
				child.button_pressed = false
				child.deselect_button()
		
		# Select this button
		button.select_button()
		focused_muscle = muscle_name
		muscle_selected.emit(muscle_name)
		print("Selected muscle: ", muscle_name)
	else:
		# Button is being toggled OFF
		button.deselect_button()
		focused_muscle = ""
		muscle_selected.emit("")
		print("Deselected muscle: ", muscle_name)
	
	# Update desaturation on all buttons
	update_button_desaturation()

func clear_selection():
	"""
	Clear the current selection programmatically.
	"""
	for child in vertical_box.get_children():
		if child is MuscleButton:
			child.button_pressed = false
			child.deselect_button()
	
	focused_muscle = ""
	muscle_selected.emit("")
	update_button_desaturation()

func update_button_desaturation():
	"""
	Update desaturation state of all buttons based on focused muscle.
	Buttons that match the focused muscle are NOT desaturated (they stay colored).
	All other buttons ARE desaturated.
	"""
	for child in vertical_box.get_children():
		if child is MuscleButton:
			var button_muscle = child.text
			
			# If there's a focused muscle, desaturate all except the focused one
			if focused_muscle != "":
				# Desaturate if this button's muscle doesn't match the focused one
				child.set_desaturated(button_muscle != focused_muscle)
			else:
				# No focus, all buttons are fully colored
				child.set_desaturated(false)
