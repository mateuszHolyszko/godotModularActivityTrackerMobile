extends Control

# Element that receives input from this drag controller.
@export var input_element: Node


var is_touching: bool = false


func _input(event: InputEvent) -> void:
	if input_element == null:
		return

	# ------------------------------------------------
	# Touch start / release
	# ------------------------------------------------

	if event is InputEventScreenTouch:
		if event.pressed:
			# Only start tracking if the touch began
			# inside this Control.
			if get_global_rect().has_point(event.position):
				is_touching = true
				input_element.set_dragging(true)
		else:
			# Always stop tracking on release.
			is_touching = false
			input_element.set_dragging(false)

		return

	# ------------------------------------------------
	# Screen drag
	# ------------------------------------------------

	if event is InputEventScreenDrag and is_touching:
		input_element.apply_swipe(event.relative.x)
