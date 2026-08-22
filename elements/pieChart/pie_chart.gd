## A simplified pie chart with side legend and custom colors.
class_name PieChart
extends Control

### For some reason if no show labels is checked custom minimum needs to be set in order for chart to render

## Data to visualize. Each element is a dictionary with:
##   "label": String - The name of the category
##   "value": float - The numeric value (must be > 0)
##   "color": Color - The color for this slice
@export var elements: Array[Dictionary] = []

@export_category("Style Properties")
@export var elements_text_color: Color = Color.WHITE
@export var elements_font_size: int = 50  # Large font for labels
@export var font: Font = ThemeDB.fallback_font
@export var showLabels: bool = true  # Whether to show labels and legend

func _draw() -> void:
	# Filter out invalid elements (value <= 0)
	var valid_elements: Array = elements.filter(func(e): return e.get("value", 0.0) > 0.0)
	
	if valid_elements.is_empty():
		# Draw empty state
		var radius: float = min(size.x, size.y) / 2.0
		var center: Vector2 = Vector2(size.x / 2.0, size.y / 2.0)
		draw_circle(center, radius * 0.8, Color.GRAY)
		var empty_text: String = ""
		var text_size: Vector2 = font.get_multiline_string_size(empty_text, HORIZONTAL_ALIGNMENT_CENTER, -1, elements_font_size)
		draw_multiline_string(
			font,
			center - text_size / 2.0,
			empty_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			text_size.x,
			elements_font_size,
			-1,
			Color.WHITE
		)
		return
	
	# Calculate total
	var total: float = 0.0
	for e in valid_elements:
		total += e.get("value", 0.0)
	
	if total <= 0:
		return
	
	var element_count: int = valid_elements.size()
	var use_two_columns: bool = element_count > 5
	
	# Calculate radius - adjust based on whether we show labels
	var radius: float
	var center: Vector2
	
	if showLabels:
		# When showing labels, position chart to the left to make room for legend
		if use_two_columns:
			# Use more width for the chart since legend takes less space
			radius = min(size.x * 0.50, size.y * 0.45)
			center = Vector2(radius + 10, size.y / 2.0)
		else:
			radius = min(size.x * 0.42, size.y * 0.45)
			center = Vector2(radius + 10, size.y / 2.0)
	else:
		# No labels - pie chart fills the whole container, centered
		radius = min(size.x, size.y) / 2.0 * 0.9  # 0.9 for some padding
		center = Vector2(size.x / 2.0, size.y / 2.0)  # EXACTLY in the middle
	
	var previous_angle: float = 0.0
	
	# Only process legend data if labels are shown
	var element_data: Array = []
	var max_text_width: float = 0.0
	var line_height: float = 0.0
	
	if showLabels:
		# First pass: collect all element data and calculate sizes
		for element in valid_elements:
			var label: String = element.get("label", "Unknown")
			var value: float = element.get("value", 0.0)
			
			# Apply ellipsis if label is longer than 7 characters
			var display_label: String = label
			if label.length() > 7 and use_two_columns:
				display_label = label.substr(0, 3) + ".. "
			
			var legend_text: String = "%s: %d" % [display_label, value]
			var text_size: Vector2 = font.get_multiline_string_size(legend_text, HORIZONTAL_ALIGNMENT_LEFT, -1, elements_font_size)
			max_text_width = max(max_text_width, text_size.x)
			line_height = text_size.y * 1.2
			element_data.append({
				"label": label,  # Keep original label for reference
				"display_label": display_label,
				"value": value,
				"color": element.get("color", Color.WHITE),
				"text": legend_text,
				"text_size": text_size
			})
		
		# Calculate legend layout
		var swatch_size: float = line_height * 0.6
		var gap: float = 15.0
		var total_width_per_item: float = max_text_width + gap + swatch_size
		var legend_spacing: float = line_height
		
		var columns: int = 2 if use_two_columns else 1
		var items_per_column: int = ceil(float(element_count) / float(columns))
		var total_legend_height: float = items_per_column * legend_spacing
		
		# Calculate starting Y position to center the legend vertically
		var start_y: float = (size.y - total_legend_height) / 2.0 + 30
		
		# Draw each slice
		for idx in range(element_data.size()):
			var data = element_data[idx]
			var color: Color = data.color
			var value: float = data.value
			
			# Calculate angles
			var percentage: float = (value / total) * 100.0
			var current_angle: float = 360.0 * (percentage / 100.0)
			
			# Draw the slice (full pie, no hole)
			draw_slice(center, radius, previous_angle, previous_angle + current_angle, color)
			
			# Draw side legend - positioned on the rightmost side
			var text_size: Vector2 = data.text_size
			
			# Calculate position based on column
			var col: int = idx / items_per_column
			var row: int = idx % items_per_column
			
			# Reset legend_y for each row (it gets modified in the drawing loop)
			var current_y: float = start_y + row * legend_spacing
			
			# Calculate x position
			var label_x: float
			if use_two_columns:
				var column_width: float = total_width_per_item + 30.0
				label_x = size.x - (columns - col) * column_width + column_width/2
			else:
				label_x = size.x - total_width_per_item
			
			# Draw the text
			draw_multiline_string(
				font,
				Vector2(label_x, current_y),
				data.text,
				HORIZONTAL_ALIGNMENT_LEFT,
				text_size.x,
				elements_font_size,
				-1,
				elements_text_color
			)
			
			# Color swatch - positioned to the right of the text
			var swatch_x: float = label_x + text_size.x + 15.0  # Gap between text and swatch
			# Use the working offset from your code
			var swatch_y: float = current_y + (text_size.y / 2.0) - (swatch_size / 2.0) - text_size.y / 1.3
			draw_rect(Rect2(swatch_x, swatch_y, swatch_size, swatch_size), color)
			
			previous_angle += current_angle
	else:
		# No labels - just draw the pie chart filling the container
		for element in valid_elements:
			var color: Color = element.get("color", Color.WHITE)
			var value: float = element.get("value", 0.0)
			
			# Calculate angles
			var percentage: float = (value / total) * 100.0
			var current_angle: float = 360.0 * (percentage / 100.0)
			
			# Draw the slice (full pie, no hole)
			draw_slice(center, radius, previous_angle, previous_angle + current_angle, color)
			
			previous_angle += current_angle

func draw_slice(center: Vector2, radius: float, angle_from: float, angle_to: float, color: Color) -> void:
	"""Draw a single pie slice (full wedge, no hole)."""
	var nb_points: int = max(round((angle_to - angle_from) / 3.0), 4)
	var points: Array[Vector2] = []
	
	# Start from center
	points.push_back(center)
	
	# Outer arc
	for i in range(nb_points + 1):
		var angle_point: float = deg_to_rad(angle_from + i * (angle_to - angle_from) / nb_points)
		points.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
	
	# Draw the slice
	draw_colored_polygon(points, color)

func set_data(data: Array[Dictionary]) -> void:
	"""
	Set the chart data.
	Each dictionary should have: {"label": String, "value": float, "color": Color}
	"""
	elements = data
	queue_redraw()

func get_total() -> float:
	"""
	Get the total value of all elements.
	"""
	var total: float = 0.0
	for e in elements:
		total += e.get("value", 0.0)
	return total

func get_element_count() -> int:
	"""
	Get the number of valid elements.
	"""
	var count: int = 0
	for e in elements:
		if e.get("value", 0.0) > 0.0:
			count += 1
	return count
