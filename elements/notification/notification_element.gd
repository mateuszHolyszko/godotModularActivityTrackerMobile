extends Control

enum Type { INFO, WARNING, ERROR, SUCCESS }

@onready var logo: TextureRect = %NotyficationTypeLogo
# info logo = res://assets/icons/Info.svg
# warning/error logo = res://assets/icons/Warning.svg
# check logo = res://assets/icons/Check.svg
@onready var bg: Panel = %Background
# info color = 80, 170, 255
# warning color = 255, 190, 60
# check color = 80, 210, 120
# error color = 255, 90, 90
@onready var notyfication_label: Label = %NotificationLabel
@onready var cancel_button: Button = %CancelButton

const ICON_INFO := preload("res://assets/icons/Info.svg")
const ICON_WARNING := preload("res://assets/icons/Warning.svg")
const ICON_CHECK := preload("res://assets/icons/Check.svg")

const COLOR_INFO := Color8(80, 170, 255)
const COLOR_WARNING := Color8(255, 190, 60)
const COLOR_CHECK := Color8(80, 210, 120)
const COLOR_ERROR := Color8(255, 90, 90)

const FADE_IN_TIME := 0.25
const FADE_OUT_TIME := 0.3

var duration: float = 3.0
var _life_tween: Tween
var _timer_task: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cancel_button.pressed.connect(_on_cancel_pressed)
	modulate.a = 0.0
	_fade_in()


func setup(type: Type, message: String, notif_duration: float = 3.0) -> void:
	duration = notif_duration
	notyfication_label.text = message

	match type:
		Type.INFO:
			logo.texture = ICON_INFO
			_apply_color(COLOR_INFO)
		Type.WARNING:
			logo.texture = ICON_WARNING
			_apply_color(COLOR_WARNING)
		Type.ERROR:
			logo.texture = ICON_WARNING
			_apply_color(COLOR_ERROR)
		Type.SUCCESS:
			logo.texture = ICON_CHECK
			_apply_color(COLOR_CHECK)

	if duration > 0.0 and not _timer_task:
		_timer_task = true
		_start_timeout()


func _apply_color(color: Color) -> void:
	# Duplicate the existing stylebox (if any) so we keep corner radius /
	# borders / shadow etc, and only override the color.
	var style: StyleBoxFlat
	var current := bg.get_theme_stylebox("panel")
	if current is StyleBoxFlat:
		style = (current as StyleBoxFlat).duplicate()
	else:
		style = StyleBoxFlat.new()
	style.bg_color = color
	bg.add_theme_stylebox_override("panel", style)


func _fade_in() -> void:
	if _life_tween and _life_tween.is_valid():
		_life_tween.kill()
	_life_tween = create_tween()
	_life_tween.tween_property(self, "modulate:a", 0.8, FADE_IN_TIME)


func _start_timeout() -> void:
	await get_tree().create_timer(duration).timeout
	# Guard in case the node was already freed (e.g. cancel pressed mid-wait).
	if is_instance_valid(self):
		dismiss()


func _on_cancel_pressed() -> void:
	dismiss()


func dismiss() -> void:
	# Prevent double-dismiss if timer and cancel button both fire.
	cancel_button.disabled = true

	if _life_tween and _life_tween.is_valid():
		_life_tween.kill()
	_life_tween = create_tween()
	_life_tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_TIME)
	_life_tween.finished.connect(queue_free)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
