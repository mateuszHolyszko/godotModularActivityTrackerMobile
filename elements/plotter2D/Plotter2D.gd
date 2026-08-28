class_name Plotter2D
extends Control


# ============================================================
# SETTINGS
# ============================================================

@export var bottom_padding: float = 30.0
@export var tick_count: int = 6
@export_range(0.0, 0.5) var y_padding_percent: float = 0.10

@export var font_size: int = 16


# Font size multipliers.
# Change these if you want to adjust the hierarchy.
const VALUE_FONT_SCALE := 1.0
const AXIS_FONT_SCALE := 0.9
const DATE_FONT_SCALE := 0.8


var value_font_size: int:
	get:
		return int(font_size * VALUE_FONT_SCALE)


var axis_font_size: int:
	get:
		return int(font_size * AXIS_FONT_SCALE)


var date_font_size: int:
	get:
		return int(font_size * DATE_FONT_SCALE)


# ============================================================
# PLOT DATA
# ============================================================

class PlotLine:
	var timestamps: PackedFloat32Array = PackedFloat32Array()
	var y_points: PackedFloat32Array = PackedFloat32Array()

	var label: String = ""
	var color: Color = Color.WHITE
	var line_width: float = 2.0

	var y_min: float = 0.0
	var y_max: float = 1.0


var plot_lines: Array[PlotLine] = []


# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
	queue_redraw()


# ============================================================
# PUBLIC API
# ============================================================

func add_plot_line(
	timestamps: PackedFloat32Array,
	values: PackedFloat32Array,
	color: Color = Color.WHITE,
	label: String = ""
) -> void:

	if timestamps.size() != values.size():
		push_error("Plotter2D: timestamps and values size mismatch")
		return

	var plot := PlotLine.new()

	plot.timestamps = timestamps
	plot.y_points = values
	plot.color = color
	plot.label = label

	_compute_y_range(plot)

	plot_lines.append(plot)

	queue_redraw()


func clear() -> void:
	plot_lines.clear()
	queue_redraw()


# ============================================================
# Y RANGE
# ============================================================

func _compute_y_range(plot: PlotLine) -> void:

	if plot.y_points.is_empty():
		plot.y_min = 0.0
		plot.y_max = 1.0
		return

	var min_value: float = INF
	var max_value: float = -INF

	for value in plot.y_points:

		if value < min_value:
			min_value = value

		if value > max_value:
			max_value = value

	# Keep the graph above zero.
	if min_value < 0.0:
		min_value = 0.0

	# Prevent division by zero when all values are identical.
	if max_value == min_value:
		max_value += 1.0

	plot.y_min = min_value
	plot.y_max = max_value


# ============================================================
# GLOBAL X RANGE
# ============================================================

func _get_global_time_range() -> Vector2:

	var min_time: float = INF
	var max_time: float = -INF

	for plot in plot_lines:

		for timestamp in plot.timestamps:

			if timestamp < min_time:
				min_time = timestamp

			if timestamp > max_time:
				max_time = timestamp

	if min_time == INF:
		return Vector2(0.0, 1.0)

	if max_time == min_time:
		max_time += 1.0

	return Vector2(min_time, max_time)


# ============================================================
# DRAW
# ============================================================

# ============================================================
# DRAW
# ============================================================

func _draw() -> void:

	if plot_lines.is_empty():
		return

	var rect := get_rect()

	var width: float = rect.size.x
	var height: float = rect.size.y - bottom_padding

	if width <= 0.0 or height <= 0.0:
		return


	# --------------------------------------------------------
	# GLOBAL TIME RANGE
	# --------------------------------------------------------

	var time_range := _get_global_time_range()

	var min_time: float = time_range.x
	var max_time: float = time_range.y

	var time_span: float = max_time - min_time

	if time_span <= 0.0:
		time_span = 1.0


	# --------------------------------------------------------
	# FONT
	# --------------------------------------------------------

	var font: Font = load("res://assets/fonts/VT323-Regular.ttf")


	# ============================================================
	# DRAW PLOTS
	# ============================================================

	for plot in plot_lines:

		if plot.timestamps.size() < 2:
			continue

		var y_span: float = plot.y_max - plot.y_min

		if y_span <= 0.0:
			y_span = 1.0
		
		# Calculate y_padding once per plot
		var y_padding: float = height * y_padding_percent


		for i in range(plot.timestamps.size() - 1):

			var timestamp_1: float = plot.timestamps[i]
			var timestamp_2: float = plot.timestamps[i + 1]

			var value_1: float = plot.y_points[i]
			var value_2: float = plot.y_points[i + 1]


			# ------------------------------------------------
			# X POSITION
			# ------------------------------------------------

			var x1: float = (
				(timestamp_1 - min_time)
				/ time_span
				* width
			)

			var x2: float = (
				(timestamp_2 - min_time)
				/ time_span
				* width
			)


			# ------------------------------------------------
			# Y POSITION
			# ------------------------------------------------

			var normalized_y1: float = (
				value_1 - plot.y_min
			) / y_span

			var y1: float = lerp(
				height - y_padding,
				y_padding,
				normalized_y1
			)

			var normalized_y2: float = (
				value_2 - plot.y_min
			) / y_span

			var y2: float = lerp(
				height - y_padding,
				y_padding,
				normalized_y2
			)


			# ------------------------------------------------
			# LINE - THICKER
			# ------------------------------------------------

			draw_line(
				Vector2(x1, y1),
				Vector2(x2, y2),
				plot.color,
				3.0
			)


			# ------------------------------------------------
			# VALUE LABEL - for current point
			# ------------------------------------------------

			var value_label: String = "%.2f" % value_1

			var label_position := Vector2(
				x1 + 4.0,
				y1 - 4.0
			)

			draw_string(
				font,
				label_position,
				value_label,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1.0,
				value_font_size,
				plot.color
			)

		# ------------------------------------------------
		# VALUE LABEL - for the LAST point
		# ------------------------------------------------
		
		# Get the last point
		var last_index: int = plot.timestamps.size() - 1
		var last_timestamp: float = plot.timestamps[last_index]
		var last_value: float = plot.y_points[last_index]
		
		# Calculate position for last point
		var last_x: float = (
			(last_timestamp - min_time)
			/ time_span
			* width
		)
		
		var last_normalized_y: float = (
			last_value - plot.y_min
		) / y_span
		
		var last_y: float = lerp(
			height - y_padding,
			y_padding,
			last_normalized_y
		)
		
		# Draw label for last point
		var last_value_label: String = "%.2f" % last_value
		var last_label_position := Vector2(
			last_x + 4.0,
			last_y - 4.0
		)
		
		draw_string(
			font,
			last_label_position,
			last_value_label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			value_font_size,
			plot.color
		)


	# ========================================================
	# X AXIS - THICKER
	# ========================================================

	var axis_y: float = height

	draw_line(
		Vector2(0.0, axis_y),
		Vector2(width, axis_y),
		Color.GRAY,
		3.0  # Increased from 2.0 to 3.0
	)


	# ========================================================
	# X AXIS TICKS
	# ========================================================

	if tick_count < 2:
		return

	# Calculate maximum label height for spacing
	var max_label_height: float = 0.0
	
	# First pass: calculate max label height
	for i in range(tick_count):
		var day_month_height = font.get_height(date_font_size)
		var year_height = font.get_height(axis_font_size)
		var total_height = day_month_height + year_height + 8.0  # +8 for spacing between day/month and year
		
		if total_height > max_label_height:
			max_label_height = total_height

	# Second pass: draw ticks and labels
	for i in range(tick_count):

		var ratio: float = float(i) / float(tick_count - 1)

		var timestamp: float = lerp(
			min_time,
			max_time,
			ratio
		)

		var x: float = ratio * width


		# ----------------------------------------------------
		# TICK - THICKER
		# ----------------------------------------------------

		draw_line(
			Vector2(x, axis_y),
			Vector2(x, axis_y + 8.0),  # Increased from 6.0 to 8.0
			Color.GRAY,
			3.0  # Increased from 2.0 to 3.0
		)


		# ----------------------------------------------------
		# DATE
		# ----------------------------------------------------

		var datetime: Dictionary = (
			Time.get_datetime_dict_from_unix_time(
				int(timestamp)
			)
		)


		var day_month: String = "%02d-%02d" % [
			datetime.day,
			datetime.month
		]

		var year: String = "%04d" % datetime.year


		# ----------------------------------------------------
		# DATE TEXT SIZE
		# ----------------------------------------------------

		var day_month_size := font.get_string_size(
			day_month,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			date_font_size
		)

		var year_size := font.get_string_size(
			year,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			axis_font_size
		)


		# ----------------------------------------------------
		# DAY / MONTH - Position below axis with proper spacing
		# ----------------------------------------------------

		# Start labels below the axis with some padding
		var label_start_y = axis_y + 12.0  # Padding from axis
		
		# Get font metrics for better positioning
		var day_month_ascent = font.get_ascent(date_font_size)
		var day_month_descent = font.get_descent(date_font_size)
		
		# Position day/month text
		var day_month_y = label_start_y + day_month_ascent

		draw_string(
			font,
			Vector2(
				x - day_month_size.x / 2.0,
				day_month_y
			),
			day_month,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			date_font_size,
			Color.WHITE
		)


		# ----------------------------------------------------
		# YEAR - Position below day/month
		# ----------------------------------------------------

		var year_ascent = font.get_ascent(axis_font_size)
		
		# Calculate spacing between day/month and year (dynamic based on font sizes)
		var spacing_between = max(4.0, min(date_font_size, axis_font_size) * 0.2)
		
		# Position year below day/month
		var year_y = day_month_y + day_month_descent + spacing_between + year_ascent

		draw_string(
			font,
			Vector2(
				x - year_size.x / 2.0,
				year_y
			),
			year,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			axis_font_size,
			Color.WHITE
		)
