extends Node

enum Type { INFO, WARNING, ERROR, SUCCESS }

## Path to your NotificationItem scene (the one using NotificationItem.gd)
const NOTIFICATION_SCENE: PackedScene = preload("res://elements/notification/NotificationElement.tscn")

var _container: VBoxContainer


## Call this once from whatever screen/root holds the VBoxContainer
## notifications should stack in, e.g. in its _ready():
##   NotificationManager.register_container(%NotificationsBox)
func register_container(container: VBoxContainer) -> void:
	_container = container


## Unregister when the container's scene is being freed, if it isn't
## the app's persistent root, to avoid holding a stale reference.
func unregister_container(container: VBoxContainer) -> void:
	if _container == container:
		_container = null


## Main entry point.
## type: NotificationManager.Type.INFO / WARNING / ERROR / SUCCESS
## message: text shown in the notification
## duration: seconds before auto-dismiss; pass 0.0 to disable auto-dismiss
func notify(type: Type, message: String, duration: float = 3.0) -> Control:
	if _container == null:
		push_error("NotificationManager: no container registered. Call register_container() first.")
		return null

	var item := NOTIFICATION_SCENE.instantiate()
	_container.add_child(item)
	item.setup(type, message, duration)
	return item


# Convenience wrappers -------------------------------------------------

func info(message: String, duration: float = 3.0) -> Control:
	return notify(Type.INFO, message, duration)


func warning(message: String, duration: float = 3.0) -> Control:
	return notify(Type.WARNING, message, duration)


func error(message: String, duration: float = 4.0) -> Control:
	return notify(Type.ERROR, message, duration)


func success(message: String, duration: float = 3.0) -> Control:
	return notify(Type.SUCCESS, message, duration)
