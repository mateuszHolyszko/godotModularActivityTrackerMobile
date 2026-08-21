# scroll_container_with_buttons.gd
extends "res://scripts/scroll/scroll_mobile_fix.gd"  

@export var scroll_top_button: Button
@export var scroll_bottom_button: Button
@export var smooth_scroll: bool = true
@export var update_interval: float = 0.5

var _scroll_tween: Tween = null
var _update_timer: Timer

func _ready():
	# Call parent _ready
	super._ready()
	
	# Initialize scroll button functionality
	_setup_scroll_buttons()

func _setup_scroll_buttons():
	if scroll_top_button:
		scroll_top_button.pressed.connect(_scroll_to_top)
	
	if scroll_bottom_button:
		scroll_bottom_button.pressed.connect(_scroll_to_bottom)
	
	# Create timer for visibility updates
	_update_timer = Timer.new()
	_update_timer.wait_time = update_interval
	_update_timer.autostart = true
	_update_timer.timeout.connect(_update_button_state)
	add_child(_update_timer)
	
	# Update button state immediately
	_update_button_state()

func _update_button_state():
	if not is_inside_tree():
		return
	
	var v_scrollbar = get_v_scroll_bar()
	if not v_scrollbar:
		return
	
	var max_scroll = v_scrollbar.max_value
	var current_scroll = v_scrollbar.value
	var page_size = v_scrollbar.page
	var is_scrollable = max_scroll > page_size
	
	if scroll_top_button:
		# Disable if at top or not scrollable
		scroll_top_button.disabled = not (is_scrollable and current_scroll > 0.0)
	
	if scroll_bottom_button:
		# Disable if at bottom or not scrollable
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

# Optional: Force update when content changes
func force_update():
	_update_button_state()
