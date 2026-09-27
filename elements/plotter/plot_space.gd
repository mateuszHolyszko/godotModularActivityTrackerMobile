class_name PlotSpace
extends Panel

var max_x: float
var max_y: float

var plot_lines: Array[PlotLine] = []
var current_plots: Array[Plotter.PlotData] = []
var current_transform: PlotTransform


func _ready() -> void:
	self.resized.connect(_on_container_resized)
	_update_size_from_container()


func _on_container_resized() -> void:
	_update_size_from_container()
	# No self-heal here anymore — Plotter listens to this same `resized`
	# signal and does a full, ordered redraw (PlotSpace -> Xaxis ->
	# YLabels) whenever it fires, which is what actually needs to happen
	# for YLabels to see PlotSpace's freshly-rebuilt lines.


func _update_size_from_container() -> void:
	# Guard against the (0,0) read that happens before layout settles.
	if self.size.x <= 0.0 or self.size.y <= 0.0:
		return

	max_x = self.size.x
	max_y = self.size.y


# ---------------------------------------------------------
# Drawing
# ---------------------------------------------------------

func rebuild(plots: Array[Plotter.PlotData], transform: PlotTransform) -> void:
	current_plots = plots
	current_transform = transform
	_clear_plot_lines()

	if plots.is_empty() or max_x <= 0.0 or max_y <= 0.0:
		return

	for plot in plots:
		var line := PlotLine.new(plot.name, plot.color)
		var screen_points := PackedVector2Array()
		var data_points := PackedVector2Array()

		for i in range(plot.dates.size()):
			var date := plot.dates[i]
			var value := plot.values[i]
			screen_points.append(transform.point_to_screen(date, value, max_x, max_y))
			data_points.append(Vector2(date, value))

		line.set_screen_points(screen_points, data_points)
		add_child(line)
		plot_lines.append(line)


func _clear_plot_lines() -> void:
	for line in plot_lines:
		line.queue_free()
	plot_lines.clear()
