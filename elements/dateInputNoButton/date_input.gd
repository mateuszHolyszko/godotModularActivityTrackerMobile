class_name DateScrollPicker
extends HBoxContainer

## Emitted live whenever the centered value of any column changes.
## Same shape as DateInputButton's duration: {"day", "month", "year"}.
signal duration_changed(duration: Dictionary)

@onready var scroll_day_container: ScrollContainer = %ScrollContainerDay
@onready var scroll_day: VBoxContainer = %ScrollContentDay

@onready var scroll_month_container: ScrollContainer = %ScrollContainerMonth
@onready var scroll_month: VBoxContainer = %ScrollContentMonth

@onready var scroll_year_container: ScrollContainer = %ScrollContainerYear
@onready var scroll_year: VBoxContainer = %ScrollContentYear

@export var item_height: float = 120.0
@export var font_size: int = 90
@export var max_years_offset: int = 10
@export var subtract_from_today: bool = true
@export var selected_color: Color = Color.WHITE
@export var unselected_color: Color = Color(1, 1, 1, 0.35)
## How long the scroll must be idle before snapping to the nearest item.
@export var snap_delay: float = 0.12

const _DAY_MAX: int = 31
const _MONTH_MAX: int = 12
## Smallest -> largest. Scrolling a column resets every column before it.
const _ORDER: Array[String] = ["day", "month", "year"]

var _selected: Dictionary = {"day": 0, "month": 0, "year": 0}

# Per-column data: container, content, max, labels, top/bottom spacers, timer, flags.
var _cols: Dictionary = {}


var _built: bool = false
func _ready() -> void:
	# Deferred so a parent's _ready() can set exports (max_years_offset,
	# item_height, font_size, ...) before the columns are generated.
	_build.call_deferred()


func _build() -> void:
	_setup_column("day", scroll_day_container, scroll_day, _DAY_MAX)
	_setup_column("month", scroll_month_container, scroll_month, _MONTH_MAX)
	_setup_column("year", scroll_year_container, scroll_year, max_years_offset)

	# set_duration() may have been called before the columns existed,
	# so clamp the stored values to the real limits now.
	for col in _cols:
		_selected[col] = clampi(_selected[col], 0, _cols[col].max)

	await get_tree().process_frame
	for col in _cols:
		_update_padding(col)
	await get_tree().process_frame
	for col in _cols:
		_scroll_to_value(col, _selected[col], false)
		_refresh_highlight(col)
	_built = true


func _setup_column(col: String, container: ScrollContainer, content: VBoxContainer, max_value: int) -> void:
	container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_theme_constant_override("separation", 0)

	# Spacers let the first/last value reach the viewport center.
	var top := Control.new()
	var bottom := Control.new()
	top.mouse_filter = Control.MOUSE_FILTER_PASS
	bottom.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_child(top)

	var labels: Array[Label] = []
	for v in range(0, max_value + 1):
		var l := Label.new()
		l.text = str(v)
		l.custom_minimum_size = Vector2(0, item_height)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", font_size)
		l.mouse_filter = Control.MOUSE_FILTER_PASS  # so dragging over labels still scrolls
		content.add_child(l)
		labels.append(l)
	content.add_child(bottom)

	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = snap_delay
	timer.timeout.connect(_snap.bind(col))
	add_child(timer)

	_cols[col] = {
		"container": container, "content": content, "max": max_value,
		"labels": labels, "top": top, "bottom": bottom, "timer": timer,
		"dragging": false, "snapping": false, "tween": null,
	}

	container.get_v_scroll_bar().value_changed.connect(_on_scrolled.bind(col))
	container.scroll_started.connect(_on_scroll_started.bind(col))
	container.scroll_ended.connect(func():
		_cols[col].dragging = false
		_cols[col].timer.start())
	container.resized.connect(_update_padding.bind(col))


func _update_padding(col: String) -> void:
	var c: Dictionary = _cols[col]
	var pad: float = maxf((c.container.size.y - item_height) / 2.0, 0.0)
	c.top.custom_minimum_size.y = pad
	c.bottom.custom_minimum_size.y = pad


## With the spacers above, item i is centered exactly when scroll_vertical == i * item_height.
func _index_from_scroll(col: String) -> int:
	var c: Dictionary = _cols[col]
	return clampi(roundi(c.container.scroll_vertical / item_height), 0, c.max)


func _on_scroll_started(col: String) -> void:
	var c: Dictionary = _cols[col]
	c.dragging = true
	# User grabbed the column mid-animation: cancel it.
	if c.tween:
		c.tween.kill()
		c.tween = null
	c.snapping = false


func _on_scrolled(_value: float, col: String) -> void:
	var c: Dictionary = _cols[col]
	if c.snapping:
		return  # our own animation, not the user

	var idx: int = _index_from_scroll(col)
	if idx != _selected[col]:
		_selected[col] = idx
		_refresh_highlight(col)
		_reset_lesser(col)
		duration_changed.emit(get_duration())

	if not c.dragging:
		c.timer.start()  # debounce for wheel / kinetic scrolling


func _reset_lesser(col: String) -> void:
	for i in _ORDER.find(col):
		var lesser: String = _ORDER[i]
		if _selected[lesser] != 0:
			_selected[lesser] = 0
			_refresh_highlight(lesser)
			_scroll_to_value(lesser, 0, true)


func _snap(col: String) -> void:
	var c: Dictionary = _cols[col]
	if c.dragging:
		return
	_scroll_to_value(col, _index_from_scroll(col), true)


func _scroll_to_value(col: String, value: int, animate: bool) -> void:
	var c: Dictionary = _cols[col]
	var target: int = roundi(clampi(value, 0, c.max) * item_height)

	if c.tween:
		c.tween.kill()
		c.tween = null
		c.snapping = false

	if not animate:
		c.container.scroll_vertical = target
		return

	c.snapping = true
	var tw := create_tween()
	c.tween = tw
	tw.tween_property(c.container, "scroll_vertical", target, 0.7) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.finished.connect(func():
		c.snapping = false
		c.tween = null)


func _refresh_highlight(col: String) -> void:
	var labels: Array = _cols[col].labels
	for i in labels.size():
		labels[i].add_theme_color_override(
			"font_color", selected_color if i == _selected[col] else unselected_color)


# --- Public API -------------------------------------------------------------

func get_duration() -> Dictionary:
	return {"day": _selected.day, "month": _selected.month, "year": _selected.year}


## Same math as DateInputButton.get_current_date().
func get_current_date() -> Dictionary:
	var today: Dictionary = Time.get_date_dict_from_system()
	var offset_days: int = _selected.year * 365 + _selected.month * 31 + _selected.day
	if subtract_from_today:
		offset_days = -offset_days
	var target_unix: int = Time.get_unix_time_from_datetime_dict(today) + offset_days * 86400
	return Time.get_date_dict_from_unix_time(target_unix)


func set_duration(duration: Dictionary) -> void:
	for col in _cols:
		_selected[col] = clampi(int(duration.get(col, 0)), 0, _cols[col].max)
		_scroll_to_value(col, _selected[col], false)
		_refresh_highlight(col)
