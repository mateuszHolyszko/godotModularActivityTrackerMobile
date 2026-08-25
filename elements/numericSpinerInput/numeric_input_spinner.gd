class_name NumericInputSpinner
extends NumericInputButton

## Drop-in replacement for NumericInputButton.
##
## Rather than opening the numeric keypad (NumericEntryMenu), this button
## opens a NumericSpinnerEntryMenu: a scrollable list of integer values the
## user picks from. Everything else -- exported properties, current_value,
## the value_changed signal, submenu wiring -- is inherited unchanged from
## NumericInputButton, so the two are fully interchangeable: just point
## entry_menu_scene_path at NumericSpinnerEntryMenu.tscn instead of
## NumericEntryMenu.tscn (or vice versa) and no other code needs to change.
##
## The spinner is exclusively integer, so is_int is forced to true here
## regardless of what's set in the editor.


func _ready() -> void:
	is_int = true
	super._ready()
