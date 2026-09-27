class_name YLabels
extends Panel

# Overlaps PlotSpace exactly, so a label positioned at a point's screen
# coordinates here lines up with that point on the drawn line.

@onready var value_label_template: Label = %ValueLabelTemplate

# Gap between the point and the near edge of each candidate box, as a
# multiple of the label's width.
const OFFSET_MULTIPLIER: float = 0.2

# Faint connector drawn from each label's edge to its point.
const CONNECTOR_WIDTH: float = 2.0
const CONNECTOR_ALPHA: float = 0.3

var max_x: float
var max_y: float

# Measured once from the template's own text ("000.00" per your template)
# and reused for every label, rather than calling reset_size() per point.
# Good enough approximation since all values are formatted the same way.
var template_size: Vector2

var labels: Array[Label] = []
var connectors: Array[Line2D] = []
var current_plots: Array[Plotter.PlotData] = []
var current_transform: PlotTransform
var current_plot_lines: Array[PlotLine] = []


func _ready() -> void:
	value_label_template.visible = false
	value_label_template.reset_size()
	template_size = value_label_template.size

	self.resized.connect(_on_container_resized)
	_update_size_from_container()


func _on_container_resized() -> void:
	_update_size_from_container()
	# No self-heal here anymore — Plotter listens to PlotSpace's resize
	# and does a full, ordered redraw (PlotSpace -> Xaxis -> YLabels)
	# whenever it fires, so YLabels always sees PlotSpace's freshly
	# rebuilt lines instead of whatever they looked like at some earlier,
	# possibly-empty moment.


func _update_size_from_container() -> void:
	# Guard against the (0,0) read that happens before layout settles.
	if self.size.x <= 0.0 or self.size.y <= 0.0:
		return

	max_x = self.size.x
	max_y = self.size.y


# ---------------------------------------------------------
# Drawing
# ---------------------------------------------------------

# `plot_lines` should be the PlotLine nodes PlotSpace built for these same
# `plots`, in the same order (index-matched) — used for overlap checks.
func rebuild(
	plots: Array[Plotter.PlotData],
	transform: PlotTransform,
	plot_lines: Array[PlotLine]
) -> void:
	current_plots = plots
	current_transform = transform
	current_plot_lines = plot_lines
	_clear_labels()

	if plots.is_empty() or max_x <= 0.0 or max_y <= 0.0:
		return

	# Collision spans every plot: as labels get placed, each new one is
	# checked against every plot line and every label placed so far,
	# regardless of which plot either one belongs to.
	var placed_rects: Array[Rect2] = []

	for plot in plots:
		for i in range(plot.values.size()):
			var date := plot.dates[i]
			var value := plot.values[i]
			var direction := _get_direction(plot, i)

			var label := _make_label(
				date, value, plot.color, transform, direction, plot_lines, placed_rects
			)
			add_child(label)
			labels.append(label)

			placed_rects.append(Rect2(label.position, template_size))


# Compares this point's value to the next one in the same plot; used only
# to pick which quadrants to try first, not as a hard rule.
# > 0: value rises going forward (prefer the top quadrants)
# < 0: value falls going forward (prefer the bottom quadrants)
#   0: last point, or a flat step (defaults to top)
func _get_direction(plot: Plotter.PlotData, index: int) -> int:
	if index >= plot.values.size() - 1:
		return 0

	var current := plot.values[index]
	var next := plot.values[index + 1]

	if next > current:
		return 1
	elif next < current:
		return -1
	return 0


func _make_label(
	date: float,
	value: float,
	color: Color,
	transform: PlotTransform,
	direction: int,
	plot_lines: Array[PlotLine],
	placed_rects: Array[Rect2]
) -> Label:
	var label: Label = value_label_template.duplicate()

	label.visible = true
	label.text = _format_value(value)
	label.modulate = color
	label.size = template_size

	var point := transform.point_to_screen(date, value, max_x, max_y)
	var label_pos := _find_label_position(point, direction, plot_lines, placed_rects)
	label.position = label_pos

	# Faint connector from the label's edge to the point it represents.
	_add_connector(label_pos, point, color)

	return label


# ---------------------------------------------------------
# Connectors: faint line from label edge to the data point
# ---------------------------------------------------------

func _add_connector(label_pos: Vector2, point: Vector2, color: Color) -> void:
	var label_center := label_pos + template_size * 0.5
	# Start at the label's edge so the line doesn't cross over the text.
	var line_start := _edge_toward(label_pos, label_center, point)

	var connector := Line2D.new()
	connector.width = CONNECTOR_WIDTH
	connector.default_color = Color(color.r, color.g, color.b, CONNECTOR_ALPHA)
	connector.antialiased = true
	# Draw behind the label but still inside this Panel.
	
	connector.add_point(line_start)
	connector.add_point(point)
	add_child(connector)
	connectors.append(connector)


# Returns the point on the label's rect edge nearest to `target`,
# walking from `center` toward `target`.
func _edge_toward(rect_pos: Vector2, center: Vector2, target: Vector2) -> Vector2:
	var dir := target - center
	if dir.length_squared() < 0.0001:
		return center

	var half := template_size * 0.5
	# Scale the direction so it hits whichever edge is closest.
	var scale_x: float = INF if absf(dir.x) < 0.0001 else half.x / absf(dir.x)
	var scale_y: float = INF if absf(dir.y) < 0.0001 else half.y / absf(dir.y)
	var t: float = minf(scale_x, scale_y)

	return center + dir * t


# ---------------------------------------------------------
# Placement: 4 candidate boxes around the point, label-sized
# ---------------------------------------------------------

# Quadrant indices. Each box is exactly `template_size`, offset from
# `point` by `template_size.x * OFFSET_MULTIPLIER` on both axes:
# 0 = top-left, 1 = top-right, 2 = bottom-left, 3 = bottom-right
func _build_quadrants(point: Vector2) -> Array[Rect2]:
	var offset := template_size.x * OFFSET_MULTIPLIER
	var w := template_size.x
	var h := template_size.y

	return [
		Rect2(Vector2(point.x - offset - w, point.y - offset - h), template_size),
		Rect2(Vector2(point.x + offset, point.y - offset - h), template_size),
		Rect2(Vector2(point.x - offset - w, point.y + offset), template_size),
		Rect2(Vector2(point.x + offset, point.y + offset), template_size),
	]


func _quadrant_order(direction: int) -> Array[int]:
	if direction >= 0:
		return [1, 0, 3, 2]  # top-right, top-left, bottom-right, bottom-left
	else:
		return [3, 2, 1, 0]  # bottom-right, bottom-left, top-right, top-left


func _find_label_position(
	point: Vector2,
	direction: int,
	plot_lines: Array[PlotLine],
	placed_rects: Array[Rect2]
) -> Vector2:
	var quadrants := _build_quadrants(point)
	var order := _quadrant_order(direction)

	for index in order:
		var quad: Rect2 = quadrants[index]

		if _rect_overlaps_any_line(quad, plot_lines):
			continue
		if _rect_overlaps_any_rect(quad, placed_rects):
			continue

		return quad.position

	# None of the 4 quadrants were clear — force the most preferred one.
	return quadrants[order[0]].position


func _rect_overlaps_any_line(rect: Rect2, plot_lines: Array[PlotLine]) -> bool:
	for line in plot_lines:
		if line != null and line.intersects_rect(rect):
			return true
	return false


func _rect_overlaps_any_rect(rect: Rect2, rects: Array[Rect2]) -> bool:
	for other in rects:
		if rect.intersects(other):
			return true
	return false


func _clear_labels() -> void:
	for label in labels:
		label.queue_free()
	labels.clear()

	for connector in connectors:
		connector.queue_free()
	connectors.clear()


func _format_value(value: float) -> String:
	return "%.2f" % value
