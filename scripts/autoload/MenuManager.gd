extends Node

signal menu_preloaded(menu_name: String)
signal all_preloads_finished

# Registered menus: name -> scene path
var _menu_paths: Dictionary = {}

# Preloaded menus: name -> PackedScene
var _preloaded_scenes: Dictionary = {}

# Menus currently being loaded async: name -> true
var _pending_preloads: Dictionary = {}

# Live instances of menus flagged is_persistent, kept alive across switches: name -> Menu
var _persistent_instances: Dictionary = {}

var _container: Control = null
var _active_menu: Menu = null
var _active_menu_name: String = ""


func _process(_delta: float) -> void:
	if _pending_preloads.is_empty():
		set_process(false)
		return

	for menu_name in _pending_preloads.keys().duplicate():
		var path: String = _menu_paths[menu_name]
		var status := ResourceLoader.load_threaded_get_status(path)

		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				_preloaded_scenes[menu_name] = ResourceLoader.load_threaded_get(path)
				_pending_preloads.erase(menu_name)
				menu_preloaded.emit(menu_name)
			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				push_error("MenuManager: failed to preload menu '%s'" % menu_name)
				_pending_preloads.erase(menu_name)
			_:
				pass  # still loading

	if _pending_preloads.is_empty():
		all_preloads_finished.emit()


func register_container(container: Control) -> void:
	_container = container


func register_menu(menu_name: String, scene_path: String) -> void:
	_menu_paths[menu_name] = scene_path


func register_menus(menus: Dictionary) -> void:
	for key in menus.keys():
		_menu_paths[key] = menus[key]


## Synchronously loads and caches a menu's scene so switch_to() is instant later.
## Blocks the calling thread until the load completes.
func preload_menu(menu_name: String) -> void:
	if not _menu_paths.has(menu_name):
		push_error("MenuManager: no menu registered under name '%s'" % menu_name)
		return

	if _preloaded_scenes.has(menu_name):
		return

	_preloaded_scenes[menu_name] = load(_menu_paths[menu_name])


func preload_menus(menu_names: Array) -> void:
	for menu_name in menu_names:
		preload_menu(menu_name)


## Starts a background load for a menu's scene. Poll is_menu_preloaded()
## or listen to menu_preloaded to know when it's ready.
func preload_menu_async(menu_name: String) -> void:
	if not _menu_paths.has(menu_name):
		push_error("MenuManager: no menu registered under name '%s'" % menu_name)
		return

	if _preloaded_scenes.has(menu_name) or _pending_preloads.has(menu_name):
		return

	var path: String = _menu_paths[menu_name]
	var err := ResourceLoader.load_threaded_request(path)
	if err != OK:
		push_error("MenuManager: failed to start preload for menu '%s' (error %d)" % [menu_name, err])
		return

	_pending_preloads[menu_name] = true
	set_process(true)


func preload_menus_async(menu_names: Array) -> void:
	for menu_name in menu_names:
		preload_menu_async(menu_name)


func is_menu_preloaded(menu_name: String) -> bool:
	return _preloaded_scenes.has(menu_name)


func is_menu_preloading(menu_name: String) -> bool:
	return _pending_preloads.has(menu_name)


## Returns load progress for a menu in the 0.0-1.0 range.
## 1.0 if already cached, 0.0 if not registered/not started.
func get_preload_progress(menu_name: String) -> float:
	if _preloaded_scenes.has(menu_name):
		return 1.0

	if not _pending_preloads.has(menu_name):
		return 0.0

	var progress: Array = []
	ResourceLoader.load_threaded_get_status(_menu_paths[menu_name], progress)
	return progress[0] if not progress.is_empty() else 0.0


## Drops the cached scene for a menu, freeing it once no instances reference it.
func unload_preloaded_menu(menu_name: String) -> void:
	_preloaded_scenes.erase(menu_name)


func clear_preloaded_menus() -> void:
	_preloaded_scenes.clear()


func switch_to(menu_name: String) -> void:
	if not _container:
		push_error("MenuManager: no container registered. Call register_container() first.")
		return

	if not _menu_paths.has(menu_name):
		push_error("MenuManager: no menu registered under name '%s'" % menu_name)
		return

	if _active_menu:
		if _active_menu.is_persistent:
			_active_menu.deactivate()
			_persistent_instances[_active_menu_name] = _active_menu
		else:
			_active_menu.close()
			_active_menu.queue_free()

	# Reuse a cached persistent instance if we have one, instead of instantiating fresh.
	if _persistent_instances.has(menu_name):
		var cached_menu: Menu = _persistent_instances[menu_name]
		_active_menu = cached_menu
		_active_menu_name = menu_name
		_active_menu.reactivate(_container)
		return

	var scene: PackedScene = _preloaded_scenes.get(menu_name)
	if not scene:
		scene = load(_menu_paths[menu_name])
	
	var new_menu: Menu = scene.instantiate()

	_active_menu = new_menu
	_active_menu_name = menu_name
	_active_menu.open(_container)

	if new_menu.is_persistent:
		_persistent_instances[menu_name] = new_menu


func get_active_menu_name() -> String:
	return _active_menu_name


func get_active_menu() -> Menu:
	return _active_menu


func is_menu_persistent_instance_cached(menu_name: String) -> bool:
	return _persistent_instances.has(menu_name)


## Fully destroys a cached persistent menu instance (e.g. once you no longer
## need its state to survive). Safe to call whether or not it's the active menu.
func discard_persistent_menu(menu_name: String) -> void:
	if not _persistent_instances.has(menu_name):
		return

	var menu: Menu = _persistent_instances[menu_name]
	_persistent_instances.erase(menu_name)

	if menu == _active_menu:
		_active_menu = null
		_active_menu_name = ""

	if is_instance_valid(menu):
		menu.is_persistent = false  # force close() to do a real teardown, not deactivate()
		menu.close()
		menu.queue_free()
