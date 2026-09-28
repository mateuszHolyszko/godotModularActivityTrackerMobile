extends Button
class_name PopupPanelButton


enum ExpandDirection {
	UP,
	DOWN,
	LEFT,
	RIGHT
}


# ---------------------------------------------------------
# Signals
# ---------------------------------------------------------

signal expanded


# ---------------------------------------------------------
# Popup
# ---------------------------------------------------------

@export var popup_panel: Panel


# ---------------------------------------------------------
# Visual
# ---------------------------------------------------------

@export var expansion_icon: Texture2D
@export var collapse_icon: Texture2D


# ---------------------------------------------------------
# Expansion
# ---------------------------------------------------------

@export var expand_direction: ExpandDirection = ExpandDirection.DOWN
@export var animation_duration: float = 0.2

@export var transition: Tween.TransitionType = Tween.TRANS_QUAD
@export var ease: Tween.EaseType = Tween.EASE_OUT


# ---------------------------------------------------------
# Positioning
# ---------------------------------------------------------

@export var set_anchors: bool = false


# ---------------------------------------------------------
# State
# ---------------------------------------------------------

var is_expanded: bool = false

var _tween: Tween
var _original_scale: Vector2


func _ready() -> void:
	pressed.connect(_on_pressed)

	if popup_panel == null:
		return

	_original_scale = popup_panel.scale

	if set_anchors:
		call_deferred("_setup_popup_position")

	_setup_pivot()

	popup_panel.visible = false
	popup_panel.scale = _collapsed_scale()

	_update_icon()


# ---------------------------------------------------------
# Input
# ---------------------------------------------------------

func _on_pressed() -> void:
	toggle()


func toggle() -> void:
	if popup_panel == null:
		return

	if is_expanded:
		collapse()
	else:
		expand()


# ---------------------------------------------------------
# Expand
# ---------------------------------------------------------

func expand() -> void:
	if popup_panel == null:
		return

	is_expanded = true

	if _tween:
		_tween.kill()

	if set_anchors:
		_setup_popup_position()

	popup_panel.visible = true

	_tween = create_tween()
	_tween.set_trans(transition)
	_tween.set_ease(ease)

	_tween.tween_property(
		popup_panel,
		"scale",
		_original_scale,
		animation_duration
	)

	_update_icon()

	expanded.emit()


# ---------------------------------------------------------
# Collapse
# ---------------------------------------------------------

func collapse() -> void:
	if popup_panel == null:
		return

	is_expanded = false

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_trans(transition)
	_tween.set_ease(ease)

	_tween.tween_property(
		popup_panel,
		"scale",
		_collapsed_scale(),
		animation_duration
	)

	_tween.tween_callback(
		func() -> void:
			if not is_expanded:
				popup_panel.visible = false
	)

	_update_icon()


# ---------------------------------------------------------
# Popup Position
# ---------------------------------------------------------

func _setup_popup_position() -> void:
	if popup_panel == null:
		return

	var button_rect := get_global_rect()

	match expand_direction:

		ExpandDirection.UP:
			# Popup bottom-left -> button top-left
			popup_panel.global_position = Vector2(
				button_rect.position.x,
				button_rect.position.y - popup_panel.size.y
			)

		ExpandDirection.DOWN:
			# Popup top-left -> button bottom-left
			popup_panel.global_position = Vector2(
				button_rect.position.x,
				button_rect.end.y
			)

		ExpandDirection.LEFT:
			# Popup top-right -> button top-left
			popup_panel.global_position = Vector2(
				button_rect.position.x - popup_panel.size.x,
				button_rect.position.y
			)

		ExpandDirection.RIGHT:
			# Popup top-left -> button top-right
			popup_panel.global_position = Vector2(
				button_rect.end.x,
				button_rect.position.y
			)


# ---------------------------------------------------------
# Collapsed Scale
# ---------------------------------------------------------

func _collapsed_scale() -> Vector2:
	match expand_direction:

		ExpandDirection.UP, ExpandDirection.DOWN:
			return Vector2(
				_original_scale.x,
				0.0
			)

		ExpandDirection.LEFT, ExpandDirection.RIGHT:
			return Vector2(
				0.0,
				_original_scale.y
			)

	return _original_scale


# ---------------------------------------------------------
# Pivot
# ---------------------------------------------------------

func _setup_pivot() -> void:
	match expand_direction:

		ExpandDirection.UP:
			popup_panel.pivot_offset = Vector2(
				popup_panel.size.x * 0.5,
				popup_panel.size.y
			)

		ExpandDirection.DOWN:
			popup_panel.pivot_offset = Vector2(
				popup_panel.size.x * 0.5,
				0.0
			)

		ExpandDirection.LEFT:
			popup_panel.pivot_offset = Vector2(
				popup_panel.size.x,
				popup_panel.size.y * 0.5
			)

		ExpandDirection.RIGHT:
			popup_panel.pivot_offset = Vector2(
				0.0,
				popup_panel.size.y * 0.5
			)


# ---------------------------------------------------------
# Icon
# ---------------------------------------------------------

func _update_icon() -> void:
	if is_expanded:
		if collapse_icon:
			icon = collapse_icon
	else:
		if expansion_icon:
			icon = expansion_icon
