## A VFlow container that displays a summary of muscle targets across all programs
class_name ProgramSummaryContainer
extends HFlowContainer

@export var label_font_size: int = 20
@export var label_spacing: int = 5
@export var show_muscle_colors: bool = true

# Reference to the label template - you can customize this in the editor
@export var label_template: Label = null

func _ready() -> void:
	# Update the summary when the node is ready
	update_summary()
	

func update_summary() -> void:
	"""
	Query all programs, sum muscle targets, and display as styled labels.
	"""
	# Clear existing children
	for child in get_children():
		child.queue_free()
	
	# Get all programs
	var programs: Array = DataManager.ProgramManager.get_all_program_objects()
	
	if programs.is_empty():
		# Display a "No programs" message
		var empty_label := create_label("No programs found", Color.WHITE)
		add_child(empty_label)
		return
	
	# Calculate total muscle breakdown across all programs
	var total_breakdown: Dictionary = {}
	
	# Initialize all muscles with 0
	for muscle in MuscleDict.get_all_muscles():
		total_breakdown[muscle] = 0
	
	# Iterate through each program and sum the breakdowns
	for program in programs:
		var program_breakdown: Dictionary = DataManager.ProgramManager.get_program_target_breakdown(program)
		
		# Add program breakdown to total
		for muscle in program_breakdown:
			if muscle in total_breakdown:
				total_breakdown[muscle] += program_breakdown[muscle]
			else:
				total_breakdown[muscle] = program_breakdown[muscle]
	
	# TWEAK 2: Keep all muscles with 0 count (don't remove them)
	var result: Dictionary = total_breakdown.duplicate()  # Keep all muscles including zeros
	
	# Sort muscles by count descending (zero-count muscles will go to the bottom)
	var sorted_muscles: Array = result.keys()
	sorted_muscles.sort_custom(func(a, b): return result[a] > result[b])
	
	# Check if any muscle has count > 0
	var has_any_exercises: bool = false
	for muscle in sorted_muscles:
		if result[muscle] > 0:
			has_any_exercises = true
			break
	
	# If no muscles found with exercises, show a message
	if not has_any_exercises:
		var empty_label := create_label("No exercise targets found", Color.WHITE)
		add_child(empty_label)
		return
	
	# Create labels for each muscle
	for muscle in sorted_muscles:
		var count: int = result[muscle]
		var color: Color
		
		if show_muscle_colors:
			color = MuscleDict.get_color(muscle)
		else:
			color = Color.WHITE
		
		# TWEAK 1: Truncate muscle names to 3 characters (no ellipsis)
		var truncated_muscle: String = muscle
		if muscle.length() > 3:
			truncated_muscle = muscle.substr(0, 3)
		
		# Create the label text with truncated name
		var label_text: String = "%s: %d" % [truncated_muscle, count]
		
		# Create and add the label
		var label := create_label(label_text, color)
		add_child(label)

func create_label(text: String, color: Color) -> Label:
	"""
	Create a styled label with the given text and background color.
	Text is always black, and the background color is applied via a StyleBox.
	"""
	var label: Label
	
	if label_template:
		# Duplicate the template if provided
		label = label_template.duplicate()
		label.text = text
	else:
		# Create a new Label
		label = Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_FILL
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Always use black text
	label.add_theme_color_override("font_color", Color.BLACK)
	label.add_theme_font_size_override("font_size", label_font_size)
	
	# Create a StyleBox with the specified background color
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = color
	stylebox.set_border_width_all(0)  # No borders
	stylebox.content_margin_left = 8
	stylebox.content_margin_right = 8
	stylebox.content_margin_top = 4
	stylebox.content_margin_bottom = 4
	
	# Apply the stylebox as the background
	label.add_theme_stylebox_override("normal", stylebox)
	
	# Add spacing between labels (will be handled by VFlowContainer)
	if label_spacing > 0:
		label.add_theme_constant_override("separation", label_spacing)
	
	# Make label visible and ready
	label.visible = true
	
	return label

func refresh() -> void:
	"""
	Refresh the summary - useful to call when programs change.
	"""
	update_summary()

# Optional: Helper method to get total exercise count across all programs
func get_total_exercise_count() -> int:
	"""
	Get the total number of exercises across all programs.
	"""
	var total: int = 0
	var programs: Array = DataManager.ProgramManager.get_all_program_objects()
	
	for program in programs:
		var breakdown: Dictionary = DataManager.ProgramManager.get_program_target_breakdown(program)
		for muscle in breakdown:
			total += breakdown[muscle]
	
	return total

# Optional: Helper method to get the most common muscle
func get_most_common_muscle() -> String:
	"""
	Get the most trained muscle across all programs.
	"""
	update_summary()
	
	var max_count: int = 0
	var most_common: String = ""
	
	for child in get_children():
		if child is Label:
			var text: String = child.text
			var parts: Array = text.split(": ")
			if parts.size() == 2:
				var muscle: String = parts[0]
				var count: int = int(parts[1])
				if count > max_count:
					max_count = count
					most_common = muscle
	
	return most_common
