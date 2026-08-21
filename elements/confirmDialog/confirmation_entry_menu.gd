class_name ConfirmationEntryMenu
extends Menu

## Code-triggered confirmation dialog.
##
## Unlike OptionEntryMenu, this node is NOT instantiated per-use — it lives
## permanently in the scene tree as a static child of whatever Menu owns it,
## starting hidden. Rather than using Menu's default open()/close() behavior
## of reparenting itself into a container, it overrides both to just
## show()/hide() in place, since it never needs to move around the tree.
##
## Usage from any other script:
##   @onready var confirm_dialog: ConfirmationEntryMenu = %ConfirmationEntryMenu
##   ...
##   confirm_dialog.request_confirmation(
##       "Delete this entry?",
##       func(): _actually_delete(),   # on_confirm
##   )
##
## Or, if you prefer signals over callbacks:
##   confirm_dialog.confirmed.connect(_on_confirmed)
##   confirm_dialog.cancelled.connect(_on_cancelled)
##   confirm_dialog.request_confirmation("Delete this entry?")

signal confirmed
signal cancelled

@onready var prompt_label: Label = %PromptLabel
@onready var confirm_button: Button = %ConfirmButton
@onready var cancel_button: Button = %CancelButton

@export var confirm_text: String = "Confirm"
@export var cancel_text: String = "Cancel"

const SUBMENU_KEY: String = "confirmation_dialog"

var _prompt_text: String = ""
var _owning_menu: Menu
var _on_confirm_callback: Callable
var _on_cancel_callback: Callable


func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	_owning_menu = _find_owning_menu()
	if _owning_menu:
		_owning_menu.add_submenu(SUBMENU_KEY, self)
	else:
		push_error("ConfirmationEntryMenu: no owning Menu found in ancestors.")
	hide()


## Overridden: stay put and just become visible, instead of Menu's default
## of reparenting into `container`. The container arg is accepted for
## signature compatibility with Menu.open() but ignored.
func open(_container: Node) -> void:
	_load_resources()
	show()
	_on_open()
	opened.emit()


## Overridden: stay put and just become invisible, instead of Menu's
## default of removing itself from its parent.
func close() -> void:
	close_all_submenus()
	_on_close()
	_unload_resources()
	hide()
	closed.emit()


func _on_open() -> void:
	prompt_label.text = _prompt_text
	confirm_button.text = confirm_text
	cancel_button.text = cancel_text


## Opens the dialog with the given prompt. on_confirm / on_cancel are optional
## one-shot callables; the confirmed / cancelled signals fire either way.
func request_confirmation(prompt: String, on_confirm: Callable = Callable(), on_cancel: Callable = Callable()) -> void:
	if _owning_menu == null:
		push_error("ConfirmationEntryMenu: no owning Menu found in ancestors.")
		return
	_prompt_text = prompt
	_on_confirm_callback = on_confirm
	_on_cancel_callback = on_cancel
	_owning_menu.open_submenu(SUBMENU_KEY)


func _on_confirm_pressed() -> void:
	confirmed.emit()
	if _on_confirm_callback.is_valid():
		_on_confirm_callback.call()
	_reset_callbacks()
	request_close()


func _on_cancel_pressed() -> void:
	cancelled.emit()
	if _on_cancel_callback.is_valid():
		_on_cancel_callback.call()
	_reset_callbacks()
	request_close()


func _reset_callbacks() -> void:
	_on_confirm_callback = Callable()
	_on_cancel_callback = Callable()


func _find_owning_menu() -> Menu:
	var n: Node = get_parent()
	while n:
		if n is Menu:
			return n
		n = n.get_parent()
	return null
