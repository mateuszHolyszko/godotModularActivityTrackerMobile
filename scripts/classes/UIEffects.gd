# UIEffects.gd
class_name UIEffects
extends RefCounted


static func fade_in(
	control: Control,
	duration: float = 0.15,
	random_delay: float = 0.03
) -> void:
	if not is_instance_valid(control):
		return

	# Remember the alpha configured on the element.
	var native_alpha := control.modulate.a

	# Start fully transparent.
	control.modulate.a = 0.0

	# Random delay between 0 and random_delay.
	var delay := randf_range(0.0, random_delay)

	var tween := control.create_tween()

	if delay > 0.0:
		tween.tween_interval(delay)

	tween.tween_property(
		control,
		"modulate:a",
		native_alpha,
		duration
	)
