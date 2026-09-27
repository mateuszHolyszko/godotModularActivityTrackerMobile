class_name Xaxis
extends Control


# Template Label lives in the scene purely as a style/format reference
# (font, size, alignment...). It's never shown itself — only duplicated,
# once per date tick, with its text swapped out.
@onready var label_template: Label = %DateLabelTemplate


# --- Tick styling ---
@export var tick_color: Color = Color.WHITE
@export var tick_length: float = 20.0
@export var tick_width: float = 4.0


# --- Label connector styling ---
@export var connector_color: Color = Color.WHITE
@export_range(0.0, 1.0) var connector_alpha: float = 0.3
@export var connector_width: float = 1.0


# --- Label staggering ---
@export var label_level_spacing: float = 0.0
@export var label_start_y: float = 20.0
@export var label_spacing_multiplier: float = 1.2
@export var label_levels: int = 4


var max_x: float
var labels: Array[Label] = []
var current_plots: Array[Plotter.PlotData] = []
var current_transform: PlotTransform
var tick_positions: PackedFloat32Array = []
var tick_levels: Array[int] = []


func _ready() -> void:
	# Xaxis/ticks are drawn at z-index 0.
	z_index = 0

	label_template.visible = false

	self.resized.connect(_on_container_resized)

	_update_size_from_container()


func _on_container_resized() -> void:
	_update_size_from_container()

	if current_transform and not current_plots.is_empty():
		rebuild(current_plots, current_transform)
	else:
		queue_redraw()


func _update_size_from_container() -> void:
	# Guard against the (0,0) read that happens before layout settles.
	if self.size.x <= 0.0:
		return

	max_x = self.size.x


# ---------------------------------------------------------
# Drawing
# ---------------------------------------------------------

func _draw() -> void:
	for i in range(tick_positions.size()):
		var x := tick_positions[i]
		var level := tick_levels[i]

		# Tick.
		draw_line(
			Vector2(x, 0.0),
			Vector2(x, tick_length),
			tick_color,
			tick_width
		)

		# Connector for staggered labels.
		if level > 0:
			var label := labels[i]

			var label_center_x := (
				label.position.x
				+ label.size.x * 0.5
			)

			var label_top_y := label.position.y

			var line_color := connector_color
			line_color.a = connector_alpha

			draw_line(
				Vector2(x, tick_length),
				Vector2(label_center_x, label_top_y),
				line_color,
				connector_width
			)


func rebuild(
	plots: Array[Plotter.PlotData],
	transform: PlotTransform
) -> void:

	current_plots = plots
	current_transform = transform

	_clear_labels()

	tick_positions.clear()
	tick_levels.clear()

	if plots.is_empty() or max_x <= 0.0:
		queue_redraw()
		return

	var dates := _collect_unique_dates(plots)

	# Stores the right edge of the last label on each level.
	var level_right_edges: Array[float] = []

	for i in range(label_levels):
		level_right_edges.append(-INF)

	for date in dates:
		var x := transform.date_to_x(date, max_x)

		var label := _make_label(date, transform)

		var label_width := label.size.x

		# Increase the effective occupied space.
		# Example:
		# 50 px label -> treated as 60 px wide.
		var effective_width := (
			label_width
			* label_spacing_multiplier
		)

		var half_width := effective_width * 0.5

		var left := x - half_width
		var right := x + half_width

		# -------------------------------------------------
		# Find the first level where the label has enough
		# horizontal space.
		# -------------------------------------------------

		var level := label_levels - 1

		for i in range(label_levels):
			if left >= level_right_edges[i]:
				level = i
				break

		# -------------------------------------------------
		# Position label using its REAL width.
		#
		# The extra spacing is only used for collision
		# detection, not for the actual label position.
		# -------------------------------------------------

		label.position.x = x - label_width * 0.5

		var level_height := (
			label.size.y
			+ label_level_spacing
		)

		label.position.y = (
			label_start_y
			+ level * level_height
		)

		# Labels are above ticks/connectors.
		label.z_index = 1

		add_child(label)
		labels.append(label)

		level_right_edges[level] = right

		tick_positions.append(x)
		tick_levels.append(level)

	queue_redraw()


func _make_label(
	date: float,
	transform: PlotTransform
) -> Label:

	var label: Label = label_template.duplicate()

	label.name = "DateLabel_%d" % int(date)
	label.visible = true
	label.text = _format_date(date)

	return label


func _clear_labels() -> void:
	for label in labels:
		label.queue_free()

	labels.clear()


# ---------------------------------------------------------
# Dates
# ---------------------------------------------------------

# Pulls every plot's x (date) values together so ticks reflect
# the union of dates across all plots, not just one.
func _collect_unique_dates(
	plots: Array[Plotter.PlotData]
) -> Array[float]:

	var seen := {}
	var dates: Array[float] = []

	for plot in plots:
		for date in plot.dates:
			if not seen.has(date):
				seen[date] = true
				dates.append(date)

	dates.sort()

	return dates


# Assumes `date` is a Unix timestamp (seconds).
func _format_date(date: float) -> String:
	var datetime := Time.get_datetime_dict_from_unix_time(
		int(date)
	)

	return "%02d-%02d" % [
		datetime["day"],
		datetime["month"]
	]
