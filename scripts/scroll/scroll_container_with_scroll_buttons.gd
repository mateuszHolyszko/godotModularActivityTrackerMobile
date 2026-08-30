# scroll_container_with_buttons.gd
extends "res://scripts/scroll/scroll_mobile_fix.gd"

signal reached_top
signal reached_bottom

@export var scroll_top_button: Button
@export var scroll_bottom_button: Button
@export var smooth_scroll: bool = true

var _scroll_tween: Tween = null
var _last_extreme: String = ""
var _scrollbar: VScrollBar

func _ready():
	super._ready()
	_setup_scroll_buttons()

func _setup_scroll_buttons():
	if scroll_top_button:
		scroll_top_button.pressed.connect(_scroll_to_top)
	
	if scroll_bottom_button:
		scroll_bottom_button.pressed.connect(_scroll_to_bottom)
	
	_connect_scrollbar_signals()
	_update_button_state()

func _connect_scrollbar_signals() -> void:
	_scrollbar = get_v_scroll_bar()
	if not _scrollbar:
		return
	
	if not _scrollbar.value_changed.is_connected(_on_scrollbar_value_changed):
		_scrollbar.value_changed.connect(_on_scrollbar_value_changed)

func _on_scrollbar_value_changed(_value: float) -> void:
	_update_button_state()
	_update_extreme_state()

func _update_extreme_state() -> void:
	if not _scrollbar:
		_scrollbar = get_v_scroll_bar()
	if not _scrollbar:
		return
	
	var max_scroll = _scrollbar.max_value
	var current_scroll = _scrollbar.value
	var page_size = _scrollbar.page
	var epsilon = 0.001
	var is_at_top = current_scroll <= epsilon
	var is_at_bottom = current_scroll >= max_scroll - page_size - epsilon
	
	if is_at_top and _last_extreme != "top":
		_last_extreme = "top"
		reached_top.emit()
	elif is_at_bottom and _last_extreme != "bottom":
		_last_extreme = "bottom"
		reached_bottom.emit()
	elif not is_at_top and not is_at_bottom:
		_last_extreme = "middle"

func _update_button_state():
	if not is_inside_tree():
		return
	
	var v_scrollbar = get_v_scroll_bar()
	if not v_scrollbar:
		return
	
	_scrollbar = v_scrollbar
	var max_scroll = v_scrollbar.max_value
	var current_scroll = v_scrollbar.value
	var page_size = v_scrollbar.page
	var is_scrollable = max_scroll > page_size
	
	if scroll_top_button:
		scroll_top_button.disabled = not (is_scrollable and current_scroll > 0.0)
	
	if scroll_bottom_button:
		scroll_bottom_button.disabled = not (is_scrollable and current_scroll < (max_scroll - page_size))

func _scroll_to_top():
	if smooth_scroll:
		_scroll_smoothly(0.0)
	else:
		scroll_vertical = 0

func _scroll_to_bottom():
	var v_scrollbar = get_v_scroll_bar()
	if not v_scrollbar:
		return
	
	var target = v_scrollbar.max_value - v_scrollbar.page
	if smooth_scroll:
		_scroll_smoothly(target)
	else:
		scroll_vertical = target

func _scroll_smoothly(target_value: float):
	if _scroll_tween and _scroll_tween.is_valid():
		_scroll_tween.kill()
	
	_scroll_tween = create_tween()
	_scroll_tween.tween_property(
		self,
		"scroll_vertical",
		target_value,
		0.3
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func force_update():
	_update_button_state()
	_update_extreme_state()
