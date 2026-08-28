extends Control

@onready var current_menu_panel: Panel = %CurrentMenuPanel
@onready var transition_rect: ColorRect = %TransitionRect
@onready var loading_panel: LoadingPanel = %GlobalLoadingPanel
@onready var notification_container: VBoxContainer = %NotyficationContainer

@export var loading_menu_scene_path: String = "res://scenes/loadingMenu/loadingMenu.tscn"
@export var init_menu_scene_path: String = "res://scenes/initMenu/initMenu.tscn"
@export var session_menu_scene_path: String = "res://scenes/sessionMenu/sessionMenu.tscn"
@export var program_menu_scene_path: String = "res://scenes/programMenu/chooseProgramMenu.tscn"
@export var data_menu_scene_path: String = "res://scenes/dataMenu/dataMenu.tscn"


func _ready() -> void:
	GlobalElements.TransitionRect = transition_rect
	GlobalElements.LoadingScreen = loading_panel
	
	NotificationManager.register_container(notification_container)
	#NotificationManager.success("container registered")
	
	MenuManager.register_container(current_menu_panel)
	#MenuManager.register_transition(transition_rect) # TODO implement transition

	MenuManager.register_menus({
		"loading": loading_menu_scene_path,
		"init": init_menu_scene_path,
		"session": session_menu_scene_path,
		"program": program_menu_scene_path,
		"data": data_menu_scene_path,
	})

	MenuManager.switch_to("loading")
	
	_run_debug_db() # DEBUG #
	
func _run_debug_db() -> void:
	var debug := DebugDB.new()
	add_child(debug)
