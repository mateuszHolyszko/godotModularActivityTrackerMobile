extends Control
class_name LoadingSpinner


@export var circle_radius: float = 3.0
@export var circle_spacing: float = 4.0
@export var max_scale: float = 2.5
@export var wave_width: float = 3.0
@export var wave_speed: float = 5.0


var _time: float = 0.0


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var step := circle_radius * 2.0 + circle_spacing

	if step <= 0.0:
		return

	var circle_count := int(size.x / step)

	if circle_count <= 0:
		return

	var total_width := (circle_count - 1) * step
	var start_x := (size.x - total_width) * 0.5
	var center_y := size.y * 0.5

	# Traveling wave position.
	var wave_position := fmod(_time * wave_speed, float(circle_count))

	for i in range(circle_count):
		var x := start_x + i * step

		var distance = abs(float(i) - wave_position)

		# Handle the wrap-around at the ends.
		distance = min(
			distance,
			float(circle_count) - distance
		)

		# Smooth falloff from the center of the wave.
		var influence := exp(
			-pow(distance / wave_width, 2.0)
		)

		var current_radius = lerp(
			circle_radius,
			circle_radius * max_scale,
			influence
		)

		draw_circle(
			Vector2(x, center_y),
			current_radius,
			Color.WHITE
		)
