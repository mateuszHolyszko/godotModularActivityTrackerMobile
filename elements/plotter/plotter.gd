class_name Plotter
extends Control


@onready var plot_space: PlotSpace = %PlotSpace
@onready var x_axis: Xaxis = %Xaxis
@onready var y_labels: YLabels = %Yvalues
@onready var legend_container: PlotterLegend = %LegendContainer

# ---------------------------------------------------------
# Plot data
# ---------------------------------------------------------

class PlotData:
	var name: String
	var color: Color
	var dates: PackedFloat32Array
	var values: PackedFloat32Array
	var min_value: float
	var max_value: float

	func _init(
		p_name: String,
		p_color: Color,
		p_dates: PackedFloat32Array,
		p_values: PackedFloat32Array
	) -> void:
		name = p_name
		color = p_color
		dates = p_dates
		values = p_values
		min_value = INF
		max_value = -INF
		for value in values:
			min_value = minf(min_value, value)
			max_value = maxf(max_value, value)

		if values.is_empty():
			min_value = 0.0
			max_value = 1.0
		elif is_equal_approx(min_value, max_value):
			min_value -= 1.0
			max_value += 1.0


var plots: Array[PlotData] = []


func _ready() -> void:
	# PlotSpace, Xaxis and YLabels all resize together (they share the
	# same layout). Listening here — once — and always doing a full,
	# ordered _redraw() is what guarantees YLabels never checks against
	# a PlotSpace that hasn't rebuilt its lines yet. Each child used to
	# self-heal independently on its own resize signal, which raced:
	# whichever fired first could rebuild against stale/empty data with
	# nothing ever telling it to try again.
	if plot_space:
		plot_space.resized.connect(_redraw)


# ---------------------------------------------------------
# Public API
# ---------------------------------------------------------

func add_plot(
	p_name: String,
	p_color: Color,
	p_dates: PackedFloat32Array,
	p_values: PackedFloat32Array
) -> void:
	plots.append(PlotData.new(p_name, p_color, p_dates, p_values))
	_redraw()
	_update_legend()


func remove_plot(p_name: String) -> void:
	for i in range(plots.size() - 1, -1, -1):
		if plots[i].name == p_name:
			plots.remove_at(i)
	_redraw()


func clear_plots() -> void:
	plots.clear()
	_redraw()

func _update_legend() -> void:
	if legend_container:
		legend_container.rebuild(plots)

# Exposes the drawn PlotLine nodes (screen-space points + collision
# helpers) so a future label-placement pass can query them directly.
func get_plot_lines() -> Array[PlotLine]:
	if plot_space:
		return plot_space.plot_lines
	return []


func _redraw() -> void:
	# Shared date bounds are computed here; each PlotData supplies its own
	# value range to consumers that map points into screen-space pixels.
	var transform := PlotTransform.from_plots(plots)

	if plot_space:
		plot_space.rebuild(plots, transform)
	if x_axis:
		x_axis.rebuild(plots, transform)
	if y_labels:
		var plot_lines: Array[PlotLine] = plot_space.plot_lines if plot_space else []
		y_labels.rebuild(plots, transform, plot_lines)
