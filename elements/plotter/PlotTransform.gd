class_name PlotTransform
extends RefCounted


# Computed once per redraw from the full `plots` array, then handed to
# whatever needs to convert data-space (date, value) into screen-space
# pixels — PlotSpace's lines, Xaxis' date ticks, and YLabels' point labels.
# Dates use one shared range; values use the range stored by each PlotData.
#
# Bounds are data-dependent, not size-dependent — a resize can re-use the
# same PlotTransform and just call the *_to_x/y methods with a new width
# or height, no need to recompute min/max.


@export var vertical_padding_ratio: float = 0.2


var min_date: float
var max_date: float


func _init(
	p_min_date: float,
	p_max_date: float
) -> void:

	min_date = p_min_date
	max_date = p_max_date


static func from_plots(
	plots: Array[Plotter.PlotData]
) -> PlotTransform:

	var min_date := INF
	var max_date := -INF

	for plot in plots:
		for date in plot.dates:
			min_date = min(min_date, date)
			max_date = max(max_date, date)

	# An empty plot collection has no date bounds to aggregate.
	if min_date == INF:
		min_date = 0.0
		max_date = 1.0
	elif is_equal_approx(min_date, max_date):
		# Prevent division by zero when all X values are identical.
		min_date -= 1.0
		max_date += 1.0

	return PlotTransform.new(min_date, max_date)


func _padded_value_bounds(plot: Plotter.PlotData) -> Vector2:
	var data_range = plot.max_value - plot.min_value
	# How much screen space the data should occupy.
	var data_screen_ratio := 1.0 - (vertical_padding_ratio * 2.0)

	# Prevent invalid values such as padding >= 50%.
	data_screen_ratio = max(data_screen_ratio, 0.01)

	# To make the original data range occupy only e.g. 60% of
	# the screen, expand the data-space range accordingly.
	var expanded_range = data_range / data_screen_ratio

	var extra_range = expanded_range - data_range

	return Vector2(
		plot.min_value - extra_range * 0.5,
		plot.max_value + extra_range * 0.5
	)


func date_ratio(date: float) -> float:
	return (date - min_date) / (max_date - min_date)


func value_ratio(value: float, plot: Plotter.PlotData) -> float:
	var bounds := _padded_value_bounds(plot)
	return (value - bounds.x) / (bounds.y - bounds.x)


func date_to_x(date: float, width: float) -> float:
	return date_ratio(date) * width


func value_to_y(value: float, height: float, plot: Plotter.PlotData) -> float:
	# Screen Y grows downward, so flip so higher values sit near the top.
	return height - (value_ratio(value, plot) * height)


func point_to_screen(
	date: float,
	value: float,
	width: float,
	height: float,
	plot: Plotter.PlotData
) -> Vector2:

	return Vector2(
		date_to_x(date, width),
		value_to_y(value, height, plot)
	)
