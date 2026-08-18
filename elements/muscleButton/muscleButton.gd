extends Button
class_name MuscleButton

# Store the muscle color for later use
var muscle_color: Color = Color.WHITE
var is_desaturated: bool = false
var is_selected: bool = false  # Add this to track selection state

# Called when the node is ready
func _ready():
	# Check if the button's text matches a muscle group
	var muscle_name = text
	if MuscleDict.MUSCLE_COLORS.has(muscle_name):
		muscle_color = MuscleDict.MUSCLE_COLORS.get(muscle_name)
		apply_muscle_style(muscle_name)
	else:
		# Optional: Fallback style for non-muscle buttons
		print("Warning: ", muscle_name, " is not a recognized muscle group")

func apply_muscle_style(muscle_name: String):
	"""
	Apply styling based on the muscle group color.
	"""
	var color = MuscleDict.MUSCLE_COLORS.get(muscle_name)
	if not color:
		return
	
	muscle_color = color
	
	# Set font color to black for all states
	add_theme_color_override("font_color", Color.BLACK)
	add_theme_color_override("font_hover_color", Color.BLACK)
	add_theme_color_override("font_pressed_color", Color.BLACK)
	add_theme_color_override("font_disabled_color", Color.BLACK)
	add_theme_color_override("font_focus_color", Color.BLACK)
	
	# Apply the color (with desaturation if active)
	var final_color = desaturate_color(color, 0.7) if is_desaturated else color
	
	# Normal state
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = final_color
	add_theme_stylebox_override("normal", normal_style)
	
	# Hover state
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = final_color
	hover_style.border_width_left = 8
	hover_style.border_color = Color.WHITE
	hover_style.border_width_bottom = 3
	hover_style.border_width_top = 3
	hover_style.border_width_right = 3
	add_theme_stylebox_override("hover", hover_style)
	
	# Pressed state
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = final_color
	pressed_style.border_width_left = 8
	pressed_style.border_color = Color.WHITE
	pressed_style.border_width_bottom = 8
	pressed_style.border_width_top = 8
	pressed_style.border_width_right = 8
	add_theme_stylebox_override("pressed", pressed_style)
	
	# If this button was selected, reapply the selection style
	if is_selected:
		select_button()

func select_button():
	"""
	Highlight this button as selected.
	"""
	var muscle_name = text
	if not MuscleDict.MUSCLE_COLORS.has(muscle_name):
		return
	
	is_selected = true  # Track that this button is selected
	
	var color = MuscleDict.MUSCLE_COLORS.get(muscle_name)
	# If desaturated, apply desaturation to selection too
	var final_color = desaturate_color(color, 0.7) if is_desaturated else color
	
	var selected_style = StyleBoxFlat.new()
	selected_style.bg_color = final_color
	selected_style.bg_color.a = 0.6
	selected_style.border_width_left = 5
	selected_style.border_color = Color.WHITE
	selected_style.border_width_bottom = 2
	selected_style.border_width_top = 2
	selected_style.border_width_right = 2
	add_theme_stylebox_override("normal", selected_style)
	
	# Make sure font stays black when selected
	add_theme_color_override("font_color", Color.BLACK)

func deselect_button():
	"""
	Remove highlight from this button.
	"""
	var muscle_name = text
	if not MuscleDict.MUSCLE_COLORS.has(muscle_name):
		return
	
	is_selected = false  # Track that this button is no longer selected
	
	# Reapply the normal style
	apply_muscle_style(muscle_name)

func desaturate_color(color: Color, amount: float) -> Color:
	"""
	Desaturate a color by the given amount (0.0 = no change, 1.0 = fully grayscale).
	"""
	# Convert to grayscale using luminance weights
	var gray = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b
	
	# Interpolate between original color and grayscale
	var desaturated = Color(
		lerp(color.r, gray, amount),
		lerp(color.g, gray, amount),
		lerp(color.b, gray, amount),
		color.a
	)
	
	return desaturated

func set_desaturated(desaturated: bool):
	"""
	Set the desaturation state of this button.
	"""
	is_desaturated = desaturated
	# Reapply the style with new desaturation state
	var muscle_name = text
	if MuscleDict.MUSCLE_COLORS.has(muscle_name):
		apply_muscle_style(muscle_name)  # This will automatically reapply selection if needed
