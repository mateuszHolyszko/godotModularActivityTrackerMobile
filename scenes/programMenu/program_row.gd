extends Control

@onready var program_button: Button = %ProgramButton
@onready var rename_button: Button = %RenameButton
@onready var delete_button: Button = %DeleteButton

# to open subMenu we do something like this : 
##func _on_open_program_pressed() -> void:
##	open_submenu("programMenu", submenu_container)
# GET PROGRAM MENU FROM and submenu_container choose_program_menu (the control that holds this control) (perhaps export those?)


func _ready():
	pass 
