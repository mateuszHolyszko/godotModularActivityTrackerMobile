extends Menu

# === Sub Menu
@onready var submenu_container: Control = %SubMenuContainer
const PROGRAM_MENU_SCENE_PATH := "res://scenes/programMenu/program/programMenu.tscn"
var _program_menu: Menu

var _program_row_scene: PackedScene = null

func _ready():
	# Load the program row scene once and cache it
	_program_row_scene = load("res://scenes/programMenu/programRow.tscn")
	
