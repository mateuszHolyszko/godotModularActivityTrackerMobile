# scroll_button_controller.gd
extends Node

@export var scroll_container: ScrollContainer
@export var scroll_top_button: Button
@export var scroll_bottom_button: Button
@export var update_interval: float = 0.5

var _update_timer: Timer

func _ready():
	# If no scroll_container assigned, try to get parent
	if not scroll_container:
		scroll_container = get_parent() as ScrollContainer
	
	if scroll_container:
		_setup_buttons()

func _setup_buttons():
	# Connect button signals
	if scroll_top_button:
		scroll_top_button.pressed.connect(_scroll_to_top)
	
	if scroll_bottom_button:
		scroll_bottom_button.pressed.connect(_scroll_to_bottom)
	
	# Create timer for visibility updates
	_update_timer = Timer.new()
	_update_timer.wait_time = update_interval
	_update_timer.autostart = true
	_update_timer.timeout.connect(_update_button_visibility)
	add_child(_update_timer)
	
	# Update visibility immediately
	_update_button_visibility()

func _update_button_visibility():
	if not scroll_container or not scroll_container.is_inside_tree():
		return
	
	var v_scrollbar = scroll_container.get_v_scroll_bar()
	if not v_scrollbar:
		return
	
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
