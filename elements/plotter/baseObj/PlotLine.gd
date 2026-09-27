class_name PlotLine
extends Line2D

# Represents one plot's connected line in screen space. Kept as its own
# Line2D node (child of PlotSpace) so it draws itself, but it also carries
# the source data points and some geometry helpers so a future label
# placement system can test for overlap against it.

var plot_name: String
var plot_color: Color

# The original (date, value) pairs this line was built from, parallel to
# `points` (which holds the screen-space coordinates). Useful later for
# tooltips or re-deriving label anchor positions.
var data_points: PackedVector2Array


func _init(p_name: String = "", p_color: Color = Color.WHITE) -> void:
	plot_name = p_name
	plot_color = p_color
	default_color = p_color
	width = 2.0
	antialiased = true
	joint_mode = Line2D.LINE_JOINT_ROUND


func set_screen_points(
	screen_points: PackedVector2Array,
	source_data_points: PackedVector2Array = PackedVector2Array()
) -> void:
	points = screen_points
	if source_data_points.size() > 0:
		data_points = source_data_points


# ---------------------------------------------------------
# Collision helpers (for future label placement)
# ---------------------------------------------------------

func get_bounding_rect() -> Rect2:
	if points.is_empty():
		return Rect2()

	var rect := Rect2(points[0], Vector2.ZERO)
	for p in points:
		rect = rect.expand(p)
	return rect


# Minimum distance from `pos` to any segment of this line. Handy for
# scoring candidate label positions ("how close is this label to the line
# itself") without doing full rect-based collision.
func distance_to_point(pos: Vector2) -> float:
	if points.size() < 2:
		if points.size() == 1:
			return points[0].distance_to(pos)
		return INF

	var min_dist := INF
	for i in range(points.size() - 1):
		var d := _distance_to_segment(pos, points[i], points[i + 1])
		min_dist = min(min_dist, d)
	return min_dist


# Rough collision test: true if any segment of this line passes through
# `rect`. Intended for checking "would a label placed here overlap this
# line" once you get to label placement.
func intersects_rect(rect: Rect2) -> bool:
	if points.size() < 2:
		return points.size() == 1 and rect.has_point(points[0])

	for i in range(points.size() - 1):
		if _segment_intersects_rect(points[i], points[i + 1], rect):
			return true
	return false


func _distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var length_sq := ab.length_squared()
	if length_sq == 0.0:
		return p.distance_to(a)

	var t := clampf((p - a).dot(ab) / length_sq, 0.0, 1.0)
	var projection := a + ab * t
	return p.distance_to(projection)


func _segment_intersects_rect(a: Vector2, b: Vector2, rect: Rect2) -> bool:
	if rect.has_point(a) or rect.has_point(b):
		return true

	var corners := [
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y),
	]
	for i in range(4):
		var c1: Vector2 = corners[i]
		var c2: Vector2 = corners[(i + 1) % 4]

		# Geometry2D.segment_intersects_segment returns the intersection
		# point (a Vector2) or null — NOT a bool. Using it directly in an
		# `if` relies on Vector2 truthiness, which doesn't behave the way
		# you'd expect and silently evaluates false either way. Compare
		# to null explicitly instead.
		var intersection = Geometry2D.segment_intersects_segment(a, b, c1, c2)
		if intersection != null:
			return true
	return false
