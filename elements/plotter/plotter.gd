class_name Plotter
extends Control


@onready var plot_space: PlotSpace = %PlotSpace
@onready var x_axis: Xaxis = %Xaxis
@onready var y_labels: YLabels = %Yvalues


# ---------------------------------------------------------
# Plot data
# ---------------------------------------------------------

class PlotData:
	var name: String
	var color: Color
	var dates: PackedFloat32Array
	var values: PackedFloat32Array

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


func remove_plot(p_name: String) -> void:
	for i in range(plots.size() - 1, -1, -1):
		if plots[i].name == p_name:
			plots.remove_at(i)
	_redraw()


func clear_plots() -> void:
	plots.clear()
	_redraw()


# Exposes the drawn PlotLine nodes (screen-space points + collision
# helpers) so a future label-placement pass can query them directly.
func get_plot_lines() -> Array[PlotLine]:
	if plot_space:
		return plot_space.plot_lines
	return []


func _redraw() -> void:
	# Bounds are computed exactly once here, then shared by every consumer
	# that needs to map data-space points into screen-space pixels.
	var transform := PlotTransform.from_plots(plots)

	if plot_space:
		plot_space.rebuild(plots, transform)
	if x_axis:
		x_axis.rebuild(plots, transform)
	if y_labels:
		var plot_lines: Array[PlotLine] = plot_space.plot_lines if plot_space else []
		y_labels.rebuild(plots, transform, plot_lines)
