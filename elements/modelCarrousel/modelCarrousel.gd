extends Node

# TODO later: Perhaps later get them from menu, and here just store the transform i need to apply for each??
@onready var bodyModel: Node3D = %WholeBodyModel
@onready var armModel: Node3D = %ArmModel
@onready var legModel: Node3D = %LegModel

@onready var camera: Camera3D = %Camera3D


@export var rotation_time: float = 4.0
@export var pause_time: float = 1.0


var models: Array[Node3D] = []

var current_model_index: int = 0
var current_angle: float = 0.0

var starting_camera_position: Vector3


func _ready() -> void:
	models = [
		bodyModel,
		armModel,
		legModel
	]

	starting_camera_position = camera.position

	for model in models:
		model.visible = false

	models[0].visible = true

	_set_camera_angle(0.0)

	_start_rotation()



func _set_camera_angle(angle: float) -> void:
	camera.position = starting_camera_position.rotated(
		Vector3.UP,
		angle
	)

	camera.look_at(Vector3.ZERO)


func _start_rotation() -> void:
	# ------------------------------------------------
	# FRONT -> BACK
	# ------------------------------------------------

	var start_angle := current_angle
	var back_angle := current_angle + PI

	var tween := create_tween()

	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_method(
		_set_camera_angle,
		start_angle,
		back_angle,
		rotation_time
	)

	# We are now at the back.
	tween.tween_callback(func():
		current_angle = back_angle
		_set_camera_angle(current_angle)
	)

	# Pause at the back.
	tween.tween_interval(pause_time)


	# ------------------------------------------------
	# BACK -> FRONT
	# ------------------------------------------------

	var front_angle := back_angle + PI

	tween.tween_method(
		_set_camera_angle,
		back_angle,
		front_angle,
		rotation_time
	)

	# We are now back at the front.
	tween.tween_callback(func():
		current_angle = front_angle
		_set_camera_angle(current_angle)
	)

	# Pause at the front.
	tween.tween_interval(pause_time)


	# ------------------------------------------------
	# SWITCH MODEL
	# ------------------------------------------------

	tween.tween_callback(_switch_model)

	# Normalize angle so it doesn't grow forever.
	tween.tween_callback(func():
		current_angle = fmod(current_angle, TAU)
		_set_camera_angle(current_angle)
	)

	# Start the next model.
	tween.tween_callback(_start_rotation)


func _switch_model() -> void:
	models[current_model_index].visible = false

	current_model_index += 1

	if current_model_index >= models.size():
		current_model_index = 0

	models[current_model_index].visible = true


func set_focused_muscle(muscle_name: String):
	"""
	Apply focus to all visible models.
	Called by the main menu when focus changes.
	"""
	for model in models:
		model.set_focused_muscle(muscle_name)
