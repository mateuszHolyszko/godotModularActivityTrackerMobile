extends Node

@onready var bodyModel: Node3D = %WholeBodyModel
@onready var armModel: Node3D = %ArmModel
@onready var legModel: Node3D = %LegModel

@onready var camera: Camera3D = %Camera3D


# ============================================================
# CONFIG
# ============================================================

@export var rotation_speed: float = 0.5
## Automatic rotation speed in radians per second.

@export var swipe_sensitivity: float = 0.01
## Rotation amount per pixel of horizontal swipe.

@export var switch_fade: ColorRect
@export var fade_duration: float = 0.25


# ============================================================
# MODELS
# ============================================================

var models: Dictionary = {}

var current_model: Node3D = null
var current_model_key: String = ""


# ============================================================
# CAMERA
# ============================================================

var current_angle: float = 0.0
var starting_camera_position: Vector3


# ============================================================
# STATE
# ============================================================

var is_dragging: bool = false

var _fade_tween: Tween


# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	# ------------------------------------------------
	# Register models
	# ------------------------------------------------

	models = {
		"body": bodyModel,
		"arm": armModel,
		"leg": legModel
	}

	# ------------------------------------------------
	# Camera setup
	# ------------------------------------------------

	starting_camera_position = camera.position

	# ------------------------------------------------
	# Hide all models
	# ------------------------------------------------

	for model in models.values():
		model.visible = false

	# ------------------------------------------------
	# Fade setup
	# ------------------------------------------------

	if switch_fade != null:
		switch_fade.modulate.a = 0.0

	# ------------------------------------------------
	# Initial model
	# ------------------------------------------------

	switch_to_display("body")


# ============================================================
# PROCESS
# ============================================================

func _process(delta: float) -> void:
	# Don't automatically rotate while the user is dragging.
	if is_dragging:
		return

	# Constant automatic rotation.
	current_angle += rotation_speed * delta

	# Prevent the angle from growing forever.
	current_angle = fmod(current_angle, TAU)

	_set_camera_angle(current_angle)


# ============================================================
# CAMERA ROTATION
# ============================================================

func _set_camera_angle(angle: float) -> void:
	camera.position = starting_camera_position.rotated(
		Vector3.UP,
		angle
	)

	camera.look_at(Vector3.ZERO)


# ============================================================
# DRAG INPUT
# ============================================================

func set_dragging(dragging: bool) -> void:
	is_dragging = dragging


func apply_swipe(delta_x: float) -> void:
	"""
	Apply horizontal swipe movement to the camera.

	Positive delta_x = swipe right.
	Negative delta_x = swipe left.
	"""

	current_angle -= delta_x * swipe_sensitivity

	current_angle = fmod(current_angle, TAU)

	_set_camera_angle(current_angle)


# ============================================================
# MODEL SWITCHING
# ============================================================

func switch_to_display(model_key: String) -> void:
	if not models.has(model_key):
		push_warning("Unknown model key: " + model_key)
		return

	# Already displaying this model.
	if current_model_key == model_key:
		return

	# No fade element assigned.
	if switch_fade == null:
		_switch_model(model_key)
		return

	# Stop previous fade.
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()

	_fade_tween = create_tween()

	# Fade in.
	_fade_tween.tween_property(
		switch_fade,
		"modulate:a",
		1.0,
		fade_duration
	)

	# Switch while covered.
	_fade_tween.tween_callback(func():
		_switch_model(model_key)
	)

	# Fade out.
	_fade_tween.tween_property(
		switch_fade,
		"modulate:a",
		0.0,
		fade_duration
	)


func _switch_model(model_key: String) -> void:
	# Hide previous model.
	if current_model != null:
		current_model.visible = false

	# Show requested model.
	current_model = models[model_key]
	current_model.visible = true

	current_model_key = model_key


# ============================================================
# MUSCLE FOCUS
# ============================================================

func set_focused_muscle(muscle_name: String) -> void:
	for model in models.values():
		model.set_focused_muscle(muscle_name)
