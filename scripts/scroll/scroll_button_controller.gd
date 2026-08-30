# scroll_button_controller.gd
extends Node

signal reached_top
signal reached_bottom

@export var scroll_container: ScrollContainer
@export var scroll_top_button: Button
@export var scroll_bottom_button: Button

var _scrollbar: VScrollBar
var _last_extreme: String = ""

func _ready():
	if not scroll_container:
		scroll_container = get_parent() as ScrollContainer
	
	if scroll_container:
		_setup_buttons()

func _setup_buttons():
	if scroll_top_button:
		scroll_top_button.pressed.connect(_scroll_to_top)
	
	if scroll_bottom_button:
		scroll_bottom_button.pressed.connect(_scroll_to_bottom)
	
	_connect_scrollbar_signals()
	_update_button_visibility()

func _connect_scrollbar_signals() -> void:
	_scrollbar = scroll_container.get_v_scroll_bar()
	if not _scrollbar:
		return
	
	if not _scrollbar.value_changed.is_connected(_on_scrollbar_value_changed):
		_scrollbar.value_changed.connect(_on_scrollbar_value_changed)

func _on_scrollbar_value_changed(_value: float) -> void:
	_update_button_visibility()
	_update_extreme_state()

func _update_extreme_state() -> void:
	if not scroll_container or not _scrollbar:
		_scrollbar = scroll_container.get_v_scroll_bar() if scroll_container else null
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

func _update_button_visibility():
	if not scroll_container or not scroll_container.is_inside_tree():
		return
	
	var v_scrollbar = scroll_container.get_v_scroll_bar()
	if not v_scrollbar:
		return
	
	_scrollbar = v_scrollbar
	var max_scroll = v_scrollbar.max_value
	var current_scroll = v_scrollbar.value
	var page_size = v_scrollbar.page
	var is_scrollable = max_scroll > page_size
	
	if scroll_top_button:
		scroll_top_button.visible = is_scrollable and current_scroll > 0.0
	
	if scroll_bottom_button:
		scroll_bottom_button.visible = is_scrollable and current_scroll < (max_scroll - page_size)

func _scroll_to_top():
	if scroll_container:
		scroll_container.scroll_vertical = 0

func _scroll_to_bottom():
	if not scroll_container:
		return
	
	var v_scrollbar = scroll_container.get_v_scroll_bar()
	if not v_scrollbar:
		return
	
	scroll_container.scroll_vertical = v_scrollbar.max_value - v_scrollbar.page
