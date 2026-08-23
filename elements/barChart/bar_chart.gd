extends Control
class_name BarChart


# ========================
# CONFIG
# ========================

@export var default_bar_color: Color = Color(0.7, 0.7, 0.7)
@export var zero_bar_alpha: float = 0.35
@export var show_zero_bars: bool = true

@export var bar_spacing: float = 10.0
@export var label_height: float = 20.0
@export var value_height: float = 16.0
@export var top_padding: float = 10.0
@export var bottom_padding: float = 10.0


# ========================
# DATA
# ========================

var data: Dictionary = {}
var max_value: float = 1.0


# ========================
# API
# ========================

func set_data(new_data: Dictionary) -> void:
	data = new_data.duplicate()
	_compute_max()
	queue_redraw()


# ========================
# INTERNAL
# ========================

func _compute_max() -> void:
	max_value = 1.0

	for v in data.values():
		if float(v) > max_value:
			max_value = float(v)


func _get_bar_color(muscle, value: float) -> Color:
	var color: Color = MuscleDict.get_color(muscle)

	# Dim zero values
	if value == 0:
		color.a *= zero_bar_alpha

	return color


# ========================
# DRAW
# ========================

func _draw() -> void:
	if data.is_empty():
		return

	var keys = data.keys()
	var count: int = keys.size()

	if count == 0:
		return

	# Calculate bar width
	var total_spacing: float = bar_spacing * (count + 1)
	var bar_width: float = (size.x - total_spacing) / count

	# Calculate available drawing height
	var available_height: float = (
		size.y
		- label_height
		- value_height
		- top_padding
		- bottom_padding
	)

	var y_base: float = size.y - label_height - bottom_padding

	var x: float = bar_spacing

	# Font used for labels and values
	var font: Font = load("res://assets/fonts/VT323-Regular.ttf")

	for key in keys:
		var value: float = float(data[key])

		# Skip zero bars if disabled
		if value == 0.0 and not show_zero_bars:
			x += bar_width + bar_spacing
			continue

		# Calculate bar height
		var ratio: float = value / max_value
		var bar_height: float = ratio * available_height

		var rect := Rect2(
			Vector2(x, y_base - bar_height),
			Vector2(bar_width, bar_height)
		)

		# ========================
		# BAR
		# ========================

		var color: Color = _get_bar_color(key, value)

		draw_rect(rect, color)


		# ========================
		# VALUE
		# ========================

		var value_text: String = str(int(value))

		draw_string(
			font,
			Vector2(
				x,
				y_base - bar_height - 20.0
			),
			value_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			bar_width,
			60
		)


		# ========================
		# LABEL
		# ========================

		var label_text: String = str(key)

		# Truncate to first 3 characters
		if label_text.length() > 3:
			label_text = label_text.substr(0, 3)

		draw_string(
			font,
			Vector2(
				x,
				size.y +20
			),
			label_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			bar_width,
			60
		)


		# Move to next bar
		x += bar_width + bar_spacing
