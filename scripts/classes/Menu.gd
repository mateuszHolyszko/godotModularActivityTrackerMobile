class_name Menu
extends Control

signal opened
signal closed

@export var resource_paths: Array[String] = []

var _submenus: Dictionary = {}   # String -> Menu # propably used only for custom input fields, so we can come back to the menu
var _resources: Dictionary = {}  # String -> Resource
var _parent_menu: Menu = null


func open(container: Node) -> void:
	_load_resources()
	container.add_child(self)
	if container is CanvasItem:
		container.show()
	_on_open()
	opened.emit()
	GlobalElements.TransitionRect.play_refresh_animation()


func close() -> void:
	close_all_submenus()
	_on_close()
	_unload_resources()
	var parent := get_parent()
	if parent:
		parent.remove_child(self)
		if parent is CanvasItem:
			parent.hide()
	closed.emit()
	GlobalElements.TransitionRect.play_refresh_animation()


# Override in subclasses for menu-specific setup (e.g. populate a list, start an animation)
func _on_open() -> void:
	pass


# Override in subclasses for menu-specific teardown
func _on_close() -> void:
	pass


func _load_resources() -> void:
	for path in resource_paths:
		if not _resources.has(path):
			_resources[path] = load(path)


func _unload_resources() -> void:
	_resources.clear()  # drop refs; Godot frees them once refcount = 0


var _menu_key: String = ""  # set automatically by add_submenu()

func add_submenu(menu_name: String, submenu: Menu) -> void:
	submenu._parent_menu = self
	submenu._menu_key = menu_name
	_submenus[menu_name] = submenu


func request_close() -> void:
	if _parent_menu:
		_parent_menu.close_submenu(_menu_key)
	else:
		close()


func open_submenu(menu_name: String, container: Node = null) -> void:
	var target := container if container else self
	_submenus[menu_name].open(target)


func close_submenu(menu_name: String) -> void:
	if not _submenus.has(menu_name):
		return
	var submenu: Menu = _submenus[menu_name]
	if is_instance_valid(submenu):
		submenu.close()
	else:
		_submenus.erase(menu_name)


func close_all_submenus() -> void:
	for key in _submenus.keys().duplicate():
		close_submenu(key)


func remove_submenu(menu_name: String) -> void:
	_submenus.erase(menu_name)


func get_resource(path: String) -> Resource:
	return _resources.get(path)
