class_name PlotTransform
extends RefCounted


# Computed once per redraw from the full `plots` array, then handed to
# whatever needs to convert data-space (date, value) into screen-space
# pixels — PlotSpace's lines, Xaxis' date ticks, and later Yaxis' value
# ticks. Centralizing this means bounds are calculated exactly once, and
# every consumer maps a given point the same way.
#
# Bounds are data-dependent, not size-dependent — a resize can re-use the
# same PlotTransform and just call the *_to_x/y methods with a new width
# or height, no need to recompute min/max.


@export var vertical_padding_ratio: float = 0.2


var min_date: float
var max_date: float
var min_value: float
var max_value: float


func _init(
	p_min_date: float,
	p_max_date: float,
	p_min_value: float,
	p_max_value: float
) -> void:

	min_date = p_min_date
	max_date = p_max_date
	min_value = p_min_value
	max_value = p_max_value


static func from_plots(
	plots: Array[Plotter.PlotData]
) -> PlotTransform:

	var min_date := INF
	var max_date := -INF
	var min_value := INF
	var max_value := -INF

	for plot in plots:
		for date in plot.dates:
			min_date = min(min_date, date)
			max_date = max(max_date, date)

		for value in plot.values:
			min_value = min(min_value, value)
			max_value = max(max_value, value)


	# Prevent division by zero when all X/Y values are identical.
	if is_equal_approx(min_date, max_date):
		min_date -= 1.0
		max_date += 1.0

	if is_equal_approx(min_value, max_value):
		min_value -= 1.0
		max_value += 1.0


	var transform := PlotTransform.new(
		min_date,
		max_date,
		min_value,
		max_value
	)

	transform._apply_vertical_padding()

	return transform


func _apply_vertical_padding() -> void:

	var data_range := max_value - min_value

	# How much screen space the data should occupy.
	var data_screen_ratio := 1.0 - (vertical_padding_ratio * 2.0)

	# Prevent invalid values such as padding >= 50%.
	data_screen_ratio = max(data_screen_ratio, 0.01)

	# To make the original data range occupy only e.g. 60% of
	# the screen, expand the data-space range accordingly.
	var expanded_range := data_range / data_screen_ratio

	var extra_range := expanded_range - data_range

	min_value -= extra_range * 0.5
	max_value += extra_range * 0.5


func date_ratio(date: float) -> float:
	return (date - min_date) / (max_date - min_date)


func value_ratio(value: float) -> float:
	return (value - min_value) / (max_value - min_value)


func date_to_x(date: float, width: float) -> float:
	return date_ratio(date) * width


func value_to_y(value: float, height: float) -> float:
	# Screen Y grows downward, so flip so higher values sit near the top.
	return height - (value_ratio(value) * height)


func point_to_screen(
	date: float,
	value: float,
	width: float,
	height: float
) -> Vector2:

	return Vector2(
		date_to_x(date, width),
		value_to_y(value, height)
	)
