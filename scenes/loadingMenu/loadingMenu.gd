class_name LoadingMenu
extends Menu

@onready var label_loading_init: Label = %LoadingLabelInitMenu
@onready var label_loading_session: Label = %LoadingLabelSession
@onready var label_loading_program: Label = %LoadingLabelProgramMenu
@onready var label_loading_data: Label = %LoadingLabelData

@export var bar_width: int = 20
@export var filled_char: String = "#"
@export var empty_char: String = "-"

# Menu name -> the label that reports its status
var _labels: Dictionary = {}
var _loading: bool = false


func _on_open() -> void:
	_labels = {
		"init": label_loading_init,
		"session": label_loading_session,
		"program": label_loading_program,
		"data": label_loading_data,
	}

	MenuManager.menu_preloaded.connect(_on_menu_preloaded)

	_loading = true
	set_process(true)

	for menu_name in _labels.keys():
		if not MenuManager.is_menu_preloaded(menu_name):
			MenuManager.preload_menu_async(menu_name)

	_refresh_all_bars()
	_check_all_loaded()


func _on_close() -> void:
	set_process(false)
	if MenuManager.menu_preloaded.is_connected(_on_menu_preloaded):
		MenuManager.menu_preloaded.disconnect(_on_menu_preloaded)


func _process(_delta: float) -> void:
	if not _loading:
		return

	_refresh_all_bars()


func _on_menu_preloaded(menu_name: String) -> void:
	if not _labels.has(menu_name):
		return

	_refresh_bar(menu_name)
	_check_all_loaded()


func _refresh_all_bars() -> void:
	for menu_name in _labels.keys():
		_refresh_bar(menu_name)


func _refresh_bar(menu_name: String) -> void:
	var label: Label = _labels.get(menu_name)
	if not label:
		return

	var progress: float = MenuManager.get_preload_progress(menu_name)
	label.text = "%s %s" % [menu_name.capitalize().rpad(8), _make_bar(progress)]


func _make_bar(progress: float) -> String:
	var filled: int = int(round(progress * bar_width))
	filled = clampi(filled, 0, bar_width)
	var empty: int = bar_width - filled

	return "[%s%s] %3d%%" % [
		filled_char.repeat(filled),
		empty_char.repeat(empty),
		int(round(progress * 100.0)),
	]


func _check_all_loaded() -> void:
	for menu_name in _labels.keys():
		if not MenuManager.is_menu_preloaded(menu_name):
			return

	_loading = false
	set_process(false)
