class_name Menu
extends Control

signal opened
signal closed
signal deactivated
signal reactivated

## If true, MenuManager will hide/detach this menu instead of closing+freeing it
## when switching away, so its state (submenus, internal vars, etc.) survives.
@export var is_persistent: bool = false

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
	if is_persistent:
		deactivate()
		return
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


## Used by MenuManager instead of close() for persistent menus: hides/detaches
## the menu but keeps resources loaded and skips _on_close(), so state survives.
func deactivate() -> void:
	# Submenus are NOT closed here — they're children of this menu, so they
	# travel with it when detached and are still there when reactivate() re-attaches it.
	_on_deactivate()
	var parent := get_parent()
	if parent:
		parent.remove_child(self)
		if parent is CanvasItem:
			parent.hide()
	deactivated.emit()


## Used by MenuManager instead of open() for persistent menus: re-attaches
## the menu without reloading resources or re-running _on_open().
func reactivate(container: Node) -> void:
	container.add_child(self)
	if container is CanvasItem:
		container.show()
	_on_reactivate()
	reactivated.emit()
	GlobalElements.TransitionRect.play_refresh_animation()


# Override in subclasses for menu-specific setup (e.g. populate a list, start an animation)
func _on_open() -> void:
	pass


# Override in subclasses for menu-specific teardown
func _on_close() -> void:
	pass


# Override in subclasses: called when a persistent menu is hidden/detached
# but NOT destroyed (e.g. pause any animations/timers, but keep state)
func _on_deactivate() -> void:
	pass


# Override in subclasses: called when a persistent menu is shown again
# after being deactivated (e.g. resume animations, refresh a timestamp)
func _on_reactivate() -> void:
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
	if not is_instance_valid(submenu):
		_submenus.erase(menu_name)
		return

	submenu.close()

	if not submenu.is_persistent:
		# A real close (not a persistent menu's deactivate) means we're actually
		# done with this submenu: drop the reference and free the node.
		_submenus.erase(menu_name)
		submenu.queue_free()


func close_all_submenus() -> void:
	for key in _submenus.keys().duplicate():
		close_submenu(key)


func remove_submenu(menu_name: String) -> void:
	_submenus.erase(menu_name)


func get_resource(path: String) -> Resource:
	return _resources.get(path)
