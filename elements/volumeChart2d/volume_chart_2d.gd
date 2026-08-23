extends Control
class_name VolumeChart2D

# ========================
# CONFIG
# ========================

@export var program_name: String = "":
	set(value):
		program_name = value
		_update_chart()

@export var bar_height: float = 20.0
@export var min_segment_width: float = 2.0  # Minimum width for tiny segments

# ========================
# INTERNAL
# ========================

var _segments: Array = []  # Array of {muscle: String, color: Color, width_ratio: float}


# ========================
# API
# ========================

func set_program(program_name: String) -> void:
	self.program_name = program_name

func refresh() -> void:
	_update_chart()


# ========================
# INTERNAL
# ========================

func _update_chart() -> void:
	_segments.clear()
	
	if program_name == "":
		queue_redraw()
		return
	
	# Get the program object
	var program = DataManager.ProgramManager.get_program(program_name)
	if not program:
		push_error("VolumeChart2D: Program '%s' not found" % program_name)
		queue_redraw()
		return
	
	# Get target breakdown
	var breakdown = DataManager.ProgramManager.get_program_target_breakdown(program)
	
	# Calculate total exercises
	var total_exercises := 0
	for count in breakdown.values():
		total_exercises += count
	
	if total_exercises == 0:
		queue_redraw()
		return
	
	# Build segments with width ratios
	for muscle in breakdown:
		var count = breakdown[muscle]
		var ratio = float(count) / float(total_exercises)
		var color = MuscleDict.get_color(muscle)
		
		_segments.append({
			"muscle": muscle,
			"color": color,
			"width_ratio": ratio,
			"count": count
		})
	
	# Sort segments by count (largest first) for visual clarity
	_segments.sort_custom(func(a, b): return a["count"] > b["count"])
	
	queue_redraw()


# ========================
# DRAW
# ========================

func _draw() -> void:
	if _segments.is_empty():
		return
	
	var rect_width = size.x
	var rect_height = bar_height
	
	# Center vertically
	var y_offset = (size.y - rect_height) / 2.0
	
	var current_x := 0.0
	
	# Draw each segment
	for segment in _segments:
		var width = max(segment["width_ratio"] * rect_width, min_segment_width)
		
		# If this is the last segment and there's rounding error, fill the rest
		if segment == _segments[-1]:
			width = rect_width - current_x
		
		# Draw the segment
		var rect = Rect2(
			Vector2(current_x, y_offset),
			Vector2(width, rect_height)
		)
		
		draw_rect(rect, segment["color"])
		
		current_x += width
	
	# Draw border
	draw_rect(
		Rect2(Vector2(0, y_offset), Vector2(rect_width, rect_height)),
		Color(0.2, 0.2, 0.2),
		false,
		1.0
	)


# ========================
# SIZE
# ========================

func _get_minimum_size() -> Vector2:
	return Vector2(50, bar_height + 4)
